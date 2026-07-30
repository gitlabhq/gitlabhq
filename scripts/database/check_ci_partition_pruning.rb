#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'zlib'
require 'logger'
require 'net/http'
require 'uri'

require_relative '../api/default_options'

# Checks for new queries that don't apply partition pruning on CI tables (p_ci_*).
#
# Reads the offender artifacts that MultiplePartitionScanDetector writes during the post-test
# auto_explain job (`<table>_multiple_partition_scans.ndjson.gz`), keeps only those whose
# fingerprint is new versus master, posts an MR comment for any not reported before, and exits
# non-zero if any remain.
#
# The set of new-versus-master fingerprints is produced upstream by merge_request_query_differ.rb
# (written as `new_query_fingerprints.txt`), which only runs in gitlab-org/gitlab MR pipelines.
# When that file is absent the differ did not run, so we skip the check.
class CheckCiPartitionPruning
  ARTIFACT_SUFFIX = '_multiple_partition_scans.ndjson.gz'
  NEW_FINGERPRINTS_FILE = 'new_query_fingerprints.txt'

  RESOLUTION_OPTIONS = [
    { title: 'Fix the query',
      detail: "add the table's partition-key filter (e.g. `partition_id`) so the planner can " \
        'prune to a single partition (ideally) or a subset of partitions.' },
    { title: 'Grant an exception',
      detail: "add the query's fingerprint to `todos:` or `allowed:` in " \
        '`scripts/database/query_analyzers.yml`.' },
    { title: 'Bypass the check',
      detail: 'apply the ~"pipeline:skip-check-ci-partition-pruning" label to skip this check ' \
        'for the current MR.' }
  ].freeze

  COVERAGE_CAVEAT =
    'Only queries that were executed by a spec in the pipeline are analyzed, so coverage may be ' \
      'partial.'

  attr_reader :logs_dir, :logger, :comment_poster

  def self.normalized_sql(offender)
    offender['normalized'].to_s.gsub(/\s+/, ' ').strip
  end

  def initialize(logs_dir, logger = nil)
    @logs_dir = logs_dir
    @logger = logger || Logger.new($stdout)
    @comment_poster = CommentPoster.new(@logger)
  end

  def run
    new_fingerprints = load_new_fingerprints

    if new_fingerprints.nil? || new_fingerprints.empty?
      logger.info "No new fingerprints found, skipping check"
      return 0
    end

    new_offenders = new_offending_queries(new_fingerprints)

    if new_offenders.any?
      logger.info(report(new_offenders))
      comment_poster.post(new_offenders)
    else
      logger.info "No new unpartitioned CI query offenders found"
    end

    new_offenders.size
  end

  private

  def report(offenders)
    separator = "-" * 72
    lines = ["New unpartitioned CI queries detected (#{offenders.size}):", separator]

    offenders.each_with_index do |offender, index|
      tables = Array(offender['tables']).join(', ')
      lines << "  #{index + 1}. #{offender['fingerprint']} [#{tables}] first seen in `#{offender['job_name']}`"
      lines << "     #{self.class.normalized_sql(offender)}"
      lines << ""
    end

    lines << separator
    lines << "How to resolve (do one of the following):"
    RESOLUTION_OPTIONS.each_with_index do |option, index|
      lines << "  #{index + 1}. #{option[:title]}: #{option[:detail]}"
    end

    lines << ""
    lines << COVERAGE_CAVEAT
    lines << separator
    lines.join("\n")
  end

  def load_new_fingerprints
    file = File.join(logs_dir, NEW_FINGERPRINTS_FILE)
    unless File.exist?(file)
      logger.info "No #{NEW_FINGERPRINTS_FILE} found; the merge request query differ did not run"
      return
    end

    Set.new(File.readlines(file, chomp: true).reject(&:empty?))
  rescue StandardError => e
    logger.warn "Could not read #{NEW_FINGERPRINTS_FILE}: #{e.message} (#{e.class})"
    nil
  end

  # One entry per unique new offending query (keyed by fingerprint), keeping only fingerprints the
  # query differ flagged as new. A query can touch several p_ci_* tables; the plan signal only
  # tells us at least one didn't prune, not which, so we merge every table it references.
  def new_offending_queries(new_fingerprints)
    new_offenders = {}

    Dir[File.join(logs_dir, "*#{ARTIFACT_SUFFIX}")].each do |file|
      table_name = File.basename(file).delete_suffix(ARTIFACT_SUFFIX)

      Zlib::GzipReader.open(file) do |gz|
        gz.each_line do |line|
          record = JSON.parse(line)
          fingerprint = record['fingerprint']
          next unless new_fingerprints.include?(fingerprint)

          offender = (new_offenders[fingerprint] ||= record.merge('tables' => []))
          offender['tables'] |= [table_name]
        end
      end
    rescue StandardError => e
      logger.warn "Could not read partition scan artifact #{file}: #{e.message} (#{e.class})"
    end

    new_offenders.values
  end

  # Posts an MR comment listing the offenders, via the REST API over Net::HTTP (no gem dependency.)
  # Append-only: each run posts a new note for offenders it has not reported before. It recognizes
  # its own past notes by a marker and reads the fingerprints they already reported.
  class CommentPoster
    MARKER = '<!-- gitlab-org/gitlab:check-ci-partition-pruning -->'
    MAX_PAGES = 20
    MAX_RETRIES = 2
    MAX_BACKOFF = 60 # seconds
    MAX_BODY_BYTESIZE = 900_000 # a note is rejected if size > 1 MiB

    attr_reader :logger

    def initialize(logger = nil)
      @logger = logger || Logger.new($stdout)
      @token = API::DEFAULT_OPTIONS[:api_token]
      @project = API::DEFAULT_OPTIONS[:project]
      @mr_iid = Host::DEFAULT_OPTIONS[:mr_iid]
      @api_url = API::DEFAULT_OPTIONS[:endpoint]
    end

    def post(offenders)
      if [@token, @project, @mr_iid, @api_url].any? { |value| value.nil? || value.empty? }
        logger.info "Skipping MR comment (missing token or MR context); gate result unaffected"
        return
      end

      reported = reported_fingerprints
      already, fresh = offenders.partition { |offender| reported.include?(offender['fingerprint']) }

      logger.info "Offenders already reported in an earlier comment: #{fingerprint_list(already)}"
      logger.info "Offenders not yet reported (posting now): #{fingerprint_list(fresh)}"

      if fresh.empty?
        logger.info "No new offenders to report; leaving existing comments as-is"
        return
      end

      logger.info "Posting a new MR comment (#{fresh.size} new offender(s))"
      create_note(comment_body(fresh))
    rescue StandardError => e
      logger.warn "Failed to post MR comment: #{e.message} (#{e.class})"
    end

    private

    # The set of offender fingerprints we have already reported across all of our comments.
    def reported_fingerprints
      our_notes = all_notes.select { |note| note['body'].to_s.include?(MARKER) }
      Set.new(our_notes.flat_map { |note| posted_fingerprints(note['body']) })
    end

    def all_notes
      notes = []
      page = 1

      while page > 0 && page <= MAX_PAGES
        response = request(Net::HTTP::Get, URI("#{notes_url}?per_page=100&page=#{page}"))
        unless response.is_a?(Net::HTTPSuccess)
          raise "could not read existing MR notes (HTTP #{response.code}): #{response.body}"
        end

        notes.concat(JSON.parse(response.body))
        page = response['x-next-page'].to_i
      end

      notes
    end

    def posted_fingerprints(text)
      text.to_s[/<!-- fingerprints:(.*?) -->/, 1].to_s.split(',').reject(&:empty?)
    end

    def create_note(text)
      response = request(Net::HTTP::Post, URI(notes_url), body: text)

      if response.is_a?(Net::HTTPSuccess)
        logger.info "Posted MR comment (HTTP #{response.code})"
      else
        logger.warn "MR comment was not posted: the API responded with HTTP #{response.code} #{response.body}"
      end
    end

    def fingerprint_list(offenders)
      return "(none)" if offenders.empty?

      sorted_fingerprints(offenders).join(', ')
    end

    def sorted_fingerprints(offenders)
      offenders.filter_map { |offender| offender['fingerprint'] }.sort
    end

    def notes_url
      "#{@api_url}/projects/#{@project}/merge_requests/#{@mr_iid}/notes"
    end

    def request(request_klass, uri, body: nil)
      retries = 0

      loop do
        response = send_request(request_klass, uri, body: body)
        return response unless retryable?(response, request_klass) && retries < MAX_RETRIES

        retries += 1
        wait_to_retry(response, retries)
      end
    end

    def send_request(request_klass, uri, body: nil)
      req = request_klass.new(uri)
      req['PRIVATE-TOKEN'] = @token
      req.set_form_data('body' => body) if body

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = 60
      http.request(req)
    end

    def retryable?(response, request_klass)
      case response
      when Net::HTTPTooManyRequests
        true
      when Net::HTTPInternalServerError, Net::HTTPBadGateway,
        Net::HTTPServiceUnavailable, Net::HTTPGatewayTimeout
        # Only retry 5xx errors for GET requests because they're idempotent.
        request_klass == Net::HTTP::Get
      else
        false
      end
    end

    def wait_to_retry(response, attempt)
      delay = retry_delay(response, attempt)

      logger.info "API request failed (HTTP #{response.code}); retrying in " \
        "#{delay}s (attempt #{attempt}/#{MAX_RETRIES})"

      sleep(delay)
    end

    # Honor the server's Retry-After (seconds) when present, otherwise back off exponentially.
    def retry_delay(response, attempt)
      requested = response['retry-after'].to_i
      delay = requested > 0 ? requested : 2**attempt
      [delay, MAX_BACKOFF].min
    end

    def comment_body(offenders)
      body = build_body(offenders, inline_full_queries: true)
      return body if body.bytesize <= MAX_BODY_BYTESIZE

      logger.info "Inlining the full queries would make the comment #{body.bytesize} bytes " \
        "(limit #{MAX_BODY_BYTESIZE}); linking to the job log instead"

      build_body(offenders, inline_full_queries: false)
    end

    # The hidden fingerprints line lets a later run recognize offenders we already reported.
    def build_body(offenders, inline_full_queries:)
      singular = offenders.size == 1
      fingerprints = sorted_fingerprints(offenders).join(',')

      rows = offenders.map do |offender|
        tables = Array(offender['tables']).map { |table| "`#{table}`" }.join(', ')
        preview = CheckCiPartitionPruning.normalized_sql(offender)
        preview = "#{preview[0..117]}..." if preview.size > 120
        "| #{tables} | `#{offender['fingerprint']}` | #{offender['job_name']} | `#{escape_pipes(preview)}` |"
      end.join("\n")

      full_queries = inline_full_queries ? full_queries_section(offenders) : job_link_section

      resolution = RESOLUTION_OPTIONS.each_with_index.map do |option, index|
        "#{index + 1}. **#{option[:title]}**: #{option[:detail]}"
      end.join("\n")

      <<~BODY
        #{MARKER}
        <!-- fingerprints:#{fingerprints} -->
        ## :warning: New unpartitioned CI queries detected

        The quer#{singular ? 'y' : 'ies'} below scan#{singular ? 's' : ''} every partition of a
        `p_ci_*` table. Unpartitioned scans on CI tables contribute to LockManager contention
        as partitions grow.

        | Partitioned tables referenced | Fingerprint | First seen in job | Query |
        |-------------------------------|-------------|-------------------|-------|
        #{rows}

        #{full_queries}

        ### :tools: How to resolve

        Do _one_ of the following:

        #{resolution}

        If you have any questions, please ask in `#g_ci-platform`.

        _#{COVERAGE_CAVEAT}_

        ----

        <small>Something doesn't look right? Share your feedback: `gitlab.com/gitlab-org/gitlab/-/work_items/607056`</small>
      BODY
    end

    def full_queries_section(offenders)
      query_rows = offenders.map do |offender|
        "| `#{offender['fingerprint']}` | `#{escape_pipes(CheckCiPartitionPruning.normalized_sql(offender))}` |"
      end.join("\n")

      <<~SECTION.chomp
        <details><summary>Full queries</summary>

        | Fingerprint | Query |
        |-------------|-------|
        #{query_rows}

        </details>
      SECTION
    end

    def job_link_section
      "The full queries are too large to include in this comment. See the [job log](#{job_url})."
    end

    def job_url
      ENV.fetch('CI_JOB_URL', nil)
    end

    # Escape pipes so query text (e.g. the `||` concat operator) doesn't break the Markdown table.
    def escape_pipes(text)
      text.gsub('|', '\|')
    end
  end
  private_constant :CommentPoster
end

if $PROGRAM_NAME == __FILE__
  path = ARGV[0]
  if path.nil? || path.empty?
    puts "Usage: #{$PROGRAM_NAME} <path/to/auto_explain-log-or-dir>"
    exit 1
  end

  logs_dir = File.directory?(path) ? path : File.dirname(path)
  exit 1 if CheckCiPartitionPruning.new(logs_dir).run > 0
end
