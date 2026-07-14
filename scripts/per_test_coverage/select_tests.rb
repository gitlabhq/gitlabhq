#!/usr/bin/env ruby
# frozen_string_literal: true

# Selects the list of test files to capture per-test coverage for in the current
# scheduled slot.
#
# Slot decision:
# - Mon-Fri UTC: delta query against the CH source-to-test reverse-lookup MV
#   for tests covering recently changed source files, plus newly-added spec
#   files, plus stale-rescue for tests last captured more than
#   STALE_INTERVAL_DAYS ago.
# - Sat-Sun UTC: ask the GitLab API how many maintenance-schedule pipelines
#   have already fired since the most recent Saturday 00:00 UTC. The first
#   weekend slot picks hash-bucket 0, the second picks bucket 1, and every
#   slot after that falls back to the weekday delta path. Slots slide forward
#   if early ones miss, so the bucket sweep is robust to occasional skipped
#   ticks.
#
# Output: three files in OUTPUT_DIR, one per test list (FOSS rspec, EE rspec,
# jest). Rspec halves are consumed by generate_rspec_pipeline.rb; the jest half
# is consumed by generate_jest_pipeline.rb. Partition by file extension: paths
# ending in _spec.js route to jest, the rest split FOSS / EE by `ee/` prefix.
#
# Exit codes:
#   0: at least one test queued, queue files written
#   2: queue is empty for this slot (caller should emit skip.yml for the child)
#   1: failure (default Ruby exception)

require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'open3'
require 'optparse'
require 'time'
require 'uri'

module PerTestCoverage
  class SelectTests
    PROJECT_DIR_DEFAULT = 'gitlab-org/gitlab'
    OUTPUT_DIR_DEFAULT = 'tmp'
    FOSS_QUEUE_FILENAME = 'per-test-coverage-queue-foss.txt'
    EE_QUEUE_FILENAME = 'per-test-coverage-queue-ee.txt'
    JEST_QUEUE_FILENAME = 'per-test-coverage-queue-jest.txt'
    SOURCE_FILE_PATHS = %w[app lib ee/app ee/lib config/initializers].freeze
    SPEC_FILE_PATHS = %w[spec ee/spec].freeze
    STALE_INTERVAL_DAYS = 14
    STALE_RESCUE_LIMIT = 100
    EMPTY_QUEUE_EXIT_CODE = 2
    # GitLab pipeline schedule (id 23503) that drives per-test-coverage capture
    # on master. The weekend bucket sweep counts prior pipelines from this
    # schedule to decide which slot of the weekend we're in.
    MAINTENANCE_SCHEDULE_ID = 23503

    # Lightweight git wrapper extracted so the spec can inject a mock without
    # shelling out to a real repo. Uses Open3.capture3 with an argv array so
    # `base_sha` and `paths` are passed straight to git without a shell, even
    # though the values are bounded today (sha from CH, paths from a frozen
    # constant).
    class Git
      def diff_files(base_sha, paths)
        return [] if base_sha.nil? || base_sha.empty?

        # `--diff-filter=ACMR` so we catch added, copied, modified, and renamed
        # files but skip deleted ones (a removed test won't run anyway).
        cmd = ['git', 'diff', '--name-only', '--diff-filter=ACMR', "#{base_sha}..HEAD", '--', *paths]
        stdout, _stderr, status = Open3.capture3(*cmd)
        return [] unless status.success?

        out = stdout.strip
        out.empty? ? [] : out.split("\n")
      end
    end

    # Minimal GitLab API client for the weekend-slot prior-pipeline lookup. The
    # spec injects a mock, so we only need one read method here.
    class GitlabApi
      DEFAULT_API_URL = 'https://gitlab.com/api/v4'

      def initialize(
        api_url: ENV.fetch('CI_API_V4_URL', DEFAULT_API_URL),
        project_id: ENV.fetch('CI_PROJECT_ID'),
        private_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'])
        @api_url = api_url
        @project_id = project_id
        @private_token = private_token
      end

      # Counts pipelines fired by `schedule_id` whose `created_at` is at or
      # after `since_time` (UTC), excluding `exclude_pipeline_id` (the current
      # pipeline, which would otherwise count itself).
      #
      # `sort=desc` is required: this endpoint returns pipelines oldest-first by
      # default, so without it `per_page=100` only ever sees the schedule's
      # earliest runs (the count of recent pipelines is then always zero, which
      # pins every weekend slot to bucket 0). Newest-first, 100 covers the
      # 2-hourly schedule comfortably (max ~24 pipelines per weekend window). If
      # the cadence ever quickens past that, paginating via the `Link` headers
      # would be the fix.
      def count_schedule_pipelines_since(schedule_id:, since_time:, exclude_pipeline_id: nil)
        uri = URI.parse(
          "#{@api_url}/projects/#{@project_id}/pipeline_schedules/#{schedule_id}/pipelines?per_page=100&sort=desc"
        )
        body = http_get(uri)
        pipelines = JSON.parse(body)
        raise "GitLab API #{uri} returned non-array: #{pipelines.class}" unless pipelines.is_a?(Array)

        pipelines.count do |pipeline|
          next false if exclude_pipeline_id && pipeline['id'] == exclude_pipeline_id

          Time.parse(pipeline['created_at']) >= since_time
        end
      end

      private

      def http_get(uri)
        req = Net::HTTP::Get.new(uri)
        # This endpoint requires a token with read_api scope.
        req['PRIVATE-TOKEN'] = @private_token if @private_token
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(req)
        end
        return res.body if res.code.to_i.between?(200, 299)

        raise "GitLab API #{res.code} for #{uri}: #{res.body.to_s[0, 200]}"
      end
    end

    def initialize(
      clickhouse_client: nil,
      gitlab_api: nil,
      now: Time.now.utc,
      git: Git.new,
      project_path: ENV.fetch('CI_PROJECT_PATH', PROJECT_DIR_DEFAULT),
      output_dir: OUTPUT_DIR_DEFAULT,
      test_file_glob: method(:default_test_file_glob))
      @clickhouse_client = clickhouse_client
      @gitlab_api = gitlab_api
      @now = now
      @git = git
      @project_path = project_path
      @output_dir = output_dir
      @test_file_glob = test_file_glob
    end

    def run!
      queue = weekend_bucket_slot? ? weekend_bucket_queue : weekday_queue

      jest, rspec = queue.uniq.partition { |path| jest_test?(path) }
      foss, ee = rspec.partition { |path| !path.start_with?('ee/') }

      FileUtils.mkdir_p(@output_dir)
      File.write(foss_queue_path, foss.join("\n"))
      File.write(ee_queue_path, ee.join("\n"))
      File.write(jest_queue_path, jest.join("\n"))

      info "Wrote #{foss.size} FOSS rspec, #{ee.size} EE rspec, #{jest.size} jest tests to the queue"

      return unless foss.empty? && ee.empty? && jest.empty?

      info "Queue is empty for this slot. Caller should emit skip.yml for the child pipeline."
      exit(EMPTY_QUEUE_EXIT_CODE)
    end

    private

    attr_reader :clickhouse_client, :gitlab_api, :now, :git, :project_path

    def info(text)
      puts "[#{self.class.name}] #{text}"
    end

    def foss_queue_path
      File.join(@output_dir, FOSS_QUEUE_FILENAME)
    end

    def ee_queue_path
      File.join(@output_dir, EE_QUEUE_FILENAME)
    end

    def jest_queue_path
      File.join(@output_dir, JEST_QUEUE_FILENAME)
    end

    # Jest specs live under spec/frontend/ or ee/spec/frontend/ and end in
    # _spec.js. The .js suffix alone is enough to disambiguate from rspec
    # because rspec specs end in _spec.rb.
    def jest_test?(path)
      path.end_with?('_spec.js')
    end

    # True when the current slot is one of the first two weekend slots since
    # Saturday 00:00 UTC, in which case run weekend_bucket_queue. Otherwise
    # (Mon-Fri, or the third weekend slot onward) returns false and the caller
    # runs the weekday delta + stale-rescue path.
    def weekend_bucket_slot?
      !weekend_bucket_index.nil?
    end

    def weekend_bucket_index
      return @weekend_bucket_index if defined?(@weekend_bucket_index)

      @weekend_bucket_index = forced_bucket_index || automatic_weekend_bucket_index
    end

    # A GLCI_PER_TEST_COVERAGE_FORCE_BUCKET of 0 or 1 runs that bucket's
    # full-glob sweep on any day, bypassing both the weekday delta and the
    # weekend API decision. The capture only runs when
    # GLCI_PER_TEST_COVERAGE_DELTA is also true (the pipeline-generate job is
    # gated on it), so both must be set to force a sweep. The force variable
    # stays unset on normal scheduled runs.
    def forced_bucket_index
      raw = ENV['GLCI_PER_TEST_COVERAGE_FORCE_BUCKET'].to_s
      return if raw.empty?

      bucket = Integer(raw, exception: false)
      raise "GLCI_PER_TEST_COVERAGE_FORCE_BUCKET must be 0 or 1, got #{raw.inspect}" unless [0, 1].include?(bucket)

      info "Forcing bucket #{bucket} via GLCI_PER_TEST_COVERAGE_FORCE_BUCKET"
      bucket
    end

    def automatic_weekend_bucket_index
      return unless now.saturday? || now.sunday?

      prior = gitlab_api.count_schedule_pipelines_since(
        schedule_id: MAINTENANCE_SCHEDULE_ID,
        since_time: weekend_start_utc,
        exclude_pipeline_id: ENV['CI_PIPELINE_ID']&.to_i
      )
      info "GitLab API reports #{prior} prior maintenance pipeline(s) since #{weekend_start_utc.iso8601}"
      case prior
      when 0 then 0
      when 1 then 1
      end
    rescue StandardError => e
      # A token, permission, or transient failure on the slot lookup must not
      # crash the capture. Fall back to the weekday delta path (nil) so the job
      # still produces a queue or a clean empty-queue skip.
      info "Weekend-slot lookup failed (#{e.message}); falling back to the weekday delta path."
      nil
    end

    # Most recent Saturday 00:00 UTC at or before `now`. Used as the anchor for
    # counting prior weekend slots.
    def weekend_start_utc
      days_back = now.saturday? ? 0 : 1
      Time.utc(now.year, now.month, now.day) - (days_back * 86_400)
    end

    def weekday_queue
      delta_tests + stale_rescue_tests
    end

    def delta_tests
      changed_source_files = git.diff_files(last_capture_sha, SOURCE_FILE_PATHS)
      new_spec_files = git.diff_files(last_capture_sha, SPEC_FILE_PATHS)

      tests_for_sources = changed_source_files.empty? ? [] : query_tests_for_source_files(changed_source_files)

      tests_for_sources + new_spec_files
    end

    def stale_rescue_tests
      sql = <<~SQL
        SELECT test_file FROM code_coverage.test_coverage_per_file FINAL
        WHERE ci_project_path = '#{escape_sql_string(project_path)}'
        GROUP BY test_file
        HAVING max(timestamp) < now() - INTERVAL #{STALE_INTERVAL_DAYS} DAY
        LIMIT #{STALE_RESCUE_LIMIT}
      SQL

      clickhouse_client.query(sql, format: 'JSONEachRow').map { |row| row['test_file'] } # rubocop:disable Rails/Pluck -- standalone script, ActiveSupport extensions not guaranteed
    end

    def weekend_bucket_queue
      @test_file_glob.call.select do |path|
        stable_hash(path) % 2 == weekend_bucket_index
      end
    end

    def stable_hash(path)
      Digest::SHA256.hexdigest(path).to_i(16)
    end

    def last_capture_sha
      @last_capture_sha ||= begin
        sql = <<~SQL
          SELECT max(captured_sha) AS sha
          FROM code_coverage.test_coverage_per_file FINAL
          WHERE ci_project_path = '#{escape_sql_string(project_path)}' AND captured_sha != ''
        SQL
        rows = clickhouse_client.query(sql, format: 'JSONEachRow')
        rows.dig(0, 'sha').to_s
      end
    end

    def query_tests_for_source_files(source_files)
      escaped = source_files.map { |f| "'#{escape_sql_string(f)}'" }.join(', ')
      sql = <<~SQL
        SELECT DISTINCT test_file FROM code_coverage.test_files_by_source_file FINAL
        WHERE ci_project_path = '#{escape_sql_string(project_path)}'
          AND source_file IN (#{escaped})
      SQL
      clickhouse_client.query(sql, format: 'JSONEachRow').map { |row| row['test_file'] } # rubocop:disable Rails/Pluck -- standalone script, ActiveSupport extensions not guaranteed
    end

    # ClickHouse uses standard SQL single-quote escaping (doubled). Project paths come from
    # CI_PROJECT_PATH and source file names come from `git diff --name-only`, so injection
    # is bounded, but a filename containing `'` would otherwise break the query.
    def escape_sql_string(value)
      value.to_s.gsub("'", "''")
    end

    def default_test_file_glob
      Dir.glob('{spec,ee/spec}/**/*_spec.{rb,js}')
    end
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  OptionParser.new do |opts|
    opts.on('--output-dir DIR', String, "Directory to write queue files into (default: tmp)") do |value|
      options[:output_dir] = value
    end

    opts.on('-h', '--help', 'Prints this help') do
      puts opts
      exit
    end
  end.parse!

  # CLI invocation: build a real ClickHouse client + GitLab API client from env vars.
  require 'gitlab_quality/test_tooling'
  ch_client = GitlabQuality::TestTooling::ClickHouse::Client.new(
    url: ENV.fetch('CLICKHOUSE_URL'),
    database: ENV.fetch('CLICKHOUSE_DATABASE'),
    username: ENV['CLICKHOUSE_USERNAME'],
    password: ENV['GLCI_CLICKHOUSE_METRICS_PASSWORD']
  )
  gitlab_api = PerTestCoverage::SelectTests::GitlabApi.new

  PerTestCoverage::SelectTests.new(
    clickhouse_client: ch_client,
    gitlab_api: gitlab_api,
    **options.compact
  ).run!
end
