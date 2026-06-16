# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'tempfile'

# Downloads per-test coverage shards from all matching jobs in the child
# pipeline triggered by per-test-coverage:trigger. Sibling to
# ChildPipelineArtifactDownloader: that one downloads from a single named job
# (the e2e:test-on-gdk flow); this one matches every job in a parallel:N child
# pipeline by regex against its name, since GitLab CI does not natively let an
# upstream job reference a downstream pipeline's artifacts.
class PerTestCoverageArtifactDownloader
  BRIDGE_NAME = 'per-test-coverage:trigger'

  # output_dir is the destination prefix passed to `unzip -d`. GitLab artifact
  # zips preserve the project-root-relative paths of their entries, so unzipping
  # at the project root (`.`) restores files to their original locations
  # (`tmp/per-test-coverage-rspec-XXX.ndjson`). Passing `tmp` would double-nest
  # to `tmp/tmp/per-test-coverage-rspec-XXX.ndjson`.
  def initialize(job_name_pattern:, output_dir: '.', process_command: nil, output_glob: nil, batch_size: 1)
    @job_name_pattern = job_name_pattern
    @output_dir = output_dir
    # Streaming: when process_command is set, shards are downloaded in batches of
    # batch_size, the command runs on each batch, then output_glob is cleared
    # before the next batch. This bounds disk to one batch instead of holding
    # every shard's artifacts at once (a full-bucket export is tens of GB).
    @process_command = process_command
    @output_glob = output_glob
    @batch_size = batch_size
    # Without output_glob the processed files are never deleted, so disk would
    # grow unbounded and silently defeat the streaming. Fail loudly instead.
    raise ArgumentError, 'output_glob is required when process_command is set' if @process_command && @output_glob.nil?

    # Trim any trailing slash so URI concatenation stays well-formed even if the
    # CI variable is set with one.
    @api_url = ENV.fetch('CI_API_V4_URL').chomp('/')
    @project_id = ENV.fetch('CI_PROJECT_ID')
    @pipeline_id = ENV.fetch('CI_PIPELINE_ID')
    @job_token = ENV.fetch('CI_JOB_TOKEN')
  end

  # Returns 0 when every matching shard downloaded successfully, 1 otherwise.
  # A missing child pipeline is treated as success-with-no-work (the empty-queue
  # path copies skip.yml so the bridge runs a single no-op job and no shards
  # exist).
  def run
    child_pipeline_id = find_child_pipeline_id
    unless child_pipeline_id
      puts "Per-test coverage: no child pipeline found via bridge '#{BRIDGE_NAME}'. Nothing to download."
      return 0
    end

    matching = find_matching_jobs(child_pipeline_id)
    if matching.empty?
      warn "Per-test coverage: no jobs in child pipeline #{child_pipeline_id} match " \
        "#{@job_name_pattern.inspect}. Exiting non-zero so the export job surfaces missing artifacts."
      return 1
    end

    FileUtils.mkdir_p(@output_dir)

    all_ok = true
    downloaded = 0
    matching.each_slice(@batch_size) do |batch|
      batch.each do |job|
        if download_artifacts(job['id'], job['name'])
          downloaded += 1
        else
          all_ok = false
        end
      end
      all_ok = false unless process_batch
    end

    puts "Per-test coverage: downloaded artifacts from #{downloaded}/#{matching.size} jobs " \
      "in child pipeline #{child_pipeline_id}."

    all_ok ? 0 : 1
  end

  private

  attr_reader :job_name_pattern, :output_dir, :api_url, :project_id, :pipeline_id, :job_token

  # Runs the configured process command on the current batch's extracted files,
  # then clears them so the next batch starts from a clean slate. A success
  # no-op when no process command is set, which preserves the plain
  # download-everything mode for callers that do their own processing.
  def process_batch
    return true unless @process_command

    # system returns nil when the command can't be spawned (e.g. not found),
    # false on a non-zero exit; distinguish them so the warning is accurate.
    ok = system(@process_command)
    if ok.nil?
      warn "Per-test coverage: process command could not be spawned: #{@process_command}"
    elsif !ok
      warn "Per-test coverage: process command exited non-zero: #{@process_command}"
    end

    clear_output
    ok
  end

  def clear_output
    return unless @output_glob

    Dir.glob(@output_glob).each { |path| File.delete(path) }
  end

  def find_child_pipeline_id
    response = api_get("projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
    bridges = JSON.parse(response.body)
    bridge = bridges.find { |b| b['name'] == BRIDGE_NAME }
    bridge&.dig('downstream_pipeline', 'id')
  end

  # Lists all jobs in the child pipeline (paginated 100 at a time) and filters
  # by @job_name_pattern. At parallel:88 across multiple test levels the list
  # can run into the hundreds, so pagination matters.
  def find_matching_jobs(child_pipeline_id)
    jobs = []
    page = 1
    loop do
      response = api_get(
        "projects/#{project_id}/pipelines/#{child_pipeline_id}/jobs?per_page=100&page=#{page}")
      batch = JSON.parse(response.body)
      # When the total is an exact multiple of 100 we make one extra request
      # that returns an empty page; cheaper than tracking the total count.
      break if batch.empty?

      jobs.concat(batch)
      break if batch.size < 100

      page += 1
    end

    jobs.select { |job| job_name_pattern.match?(job['name']) }
  end

  def download_artifacts(job_id, job_name)
    uri = URI("#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
    redirect_limit = 5
    redirect_count = 0

    while redirect_count < redirect_limit
      # Only attach the JOB-TOKEN when talking to our own GitLab API host AND
      # over HTTPS. The artifacts endpoint redirects to GCS, and forwarding the
      # token to either a third-party host or to an http:// follow-up would
      # leak a CI credential.
      response = http_get(uri, with_auth: api_host_https?(uri))

      case response
      when Net::HTTPSuccess
        return extract(response.body, job_name, job_id)
      when Net::HTTPRedirection
        redirect_count += 1
        location = response['location']
        next_uri = resolve_redirect(uri, location)
        unless next_uri
          warn "Per-test coverage: malformed Location header #{location.inspect} for #{job_name} (#{job_id})"
          return false
        end

        uri = next_uri
      else
        warn "Per-test coverage: HTTP #{response.code} downloading #{job_name} (#{job_id}): " \
          "#{response.body.to_s[0, 200]}"
        return false
      end
    end

    warn "Per-test coverage: too many redirects downloading #{job_name} (#{job_id})"
    false
  end

  # Resolves a redirect target relative to the previous URI per RFC 7231 section 7.1.2.
  # Returns nil if the Location is empty, malformed, or resolves to something
  # without a host so the caller can warn and fail the shard cleanly.
  def resolve_redirect(previous_uri, location)
    return if location.nil? || location.empty?

    resolved = URI.join(previous_uri.to_s, location)
    resolved.host ? resolved : nil
  rescue URI::InvalidURIError
    nil
  end

  def api_host_https?(uri)
    api_uri = URI(api_url)
    uri.host == api_uri.host && uri.port == api_uri.port && uri.scheme == 'https'
  end

  def extract(body, job_name, job_id)
    success = false
    Tempfile.create(['artifacts', '.zip']) do |tempfile|
      tempfile.binmode
      tempfile.write(body)
      tempfile.flush

      unless system('unzip', '-o', '-q', tempfile.path, '-d', output_dir)
        warn "Per-test coverage: unzip exited #{$?.exitstatus} on artifacts from " \
          "#{job_name} (#{job_id})"
        next
      end

      success = true
    end
    success
  end

  def api_get(endpoint)
    response = http_get(URI("#{api_url}/#{endpoint}"))
    raise "Per-test coverage: API request failed (HTTP #{response.code}): #{response.body}" \
      unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def http_get(uri, with_auth: true)
    request = Net::HTTP::Get.new(uri)
    request['JOB-TOKEN'] = job_token if with_auth
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
  end
end
