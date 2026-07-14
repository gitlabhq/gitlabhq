# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    class CronJobs
      SCHEDULE_PATH = Rails.root.join('config/schedule.yml')
      EE_SCHEDULE_PATH = Rails.root.join('ee/config/schedule.yml')
      SAAS_SCHEDULE_PATH = Rails.root.join('ee/config/schedule_saas.yml')
      JH_SCHEDULE_PATH = Rails.root.join('jh/config/schedule.yml')
      # Keys a user may override via `gitlab.yml` (via `cron_jobs` config key)
      USER_OVERRIDABLE_CONFIG_KEYS = %w[cron args].freeze

      class << self
        # @return [Gitlab::SidekiqConfig::CronJobs]
        def config
          @config ||= new
        end

        def reset!
          @config = nil
        end
      end

      def initialize
        @static_jobs = load_schedule_files(schedule_paths)
        @dynamic_jobs = {}
      end

      # Timezone string applied to every cron job, or `nil` when no override is configured.
      # A follow-up MR will wire the source.
      def timezone_override
        nil
      end

      # Registers a dynamic job or overrides fields on an existing static job.
      # Expires the memoized {#jobs} cache.
      #
      # @param name [String]
      # @param config [Hash]
      def set_job(name, config)
        @dynamic_jobs[name.to_s] = config.stringify_keys
        expire_jobs_cache!
      end

      # Immutable merged snapshot with timezone override applied. Memoized.
      # Use {#set_job} to register dynamic jobs; they are reflected on the next call.
      #
      # @return [Hash{String => Hash}]
      def jobs
        @jobs ||= begin
          merged = @static_jobs.transform_values(&:dup)
          @dynamic_jobs.each { |name, dyn| merged[name] = (merged[name] || {}).merge(dyn) }
          apply_user_overrides(merged)
          apply_timezone_override(merged)
          merged.each_value(&:freeze).freeze
        end
      end

      private_class_method :new

      private

      def expire_jobs_cache!
        @jobs = nil
      end

      # @return [Array<Pathname>]
      def schedule_paths
        paths = [SCHEDULE_PATH]
        paths << EE_SCHEDULE_PATH if Gitlab.ee?
        paths << SAAS_SCHEDULE_PATH if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- SaaS schedule file gating
        paths << JH_SCHEDULE_PATH if Gitlab.jh?
        paths
      end

      # @param paths [Array<Pathname>]
      # @return [Hash{String => Hash}]
      def load_schedule_files(paths)
        paths.each_with_object({}) do |path, jobs|
          load_schedule_file(path).each do |name, config|
            jobs[name.to_s] = jobs.fetch(name.to_s, {}).merge(config.stringify_keys)
          end
        end
      end

      # @param path [Pathname]
      # @return [Hash]
      def load_schedule_file(path)
        return {} unless File.exist?(path)

        YAML.safe_load_file(path) || {}
      end

      # Applies user-supplied overrides from `gitlab.yml` in place.
      #
      # @param jobs [Hash{String => Hash}]
      def apply_user_overrides(jobs)
        user_configured_overrides.each do |name, overrides|
          job = jobs[name.to_s]
          next unless job && overrides.is_a?(Hash)

          overrides.stringify_keys.slice(*USER_OVERRIDABLE_CONFIG_KEYS).each do |key, value|
            next if value.nil?

            default_value = job[key]
            if default_value != value
              Gitlab::AppLogger.warn(
                "cron_jobs config: '#{name}.#{key}' overridden by instance configuration " \
                  "(default: #{default_value.inspect}, configured: #{value.inspect})"
              )
            end

            job[key] = value
          end
        end
      end

      # @return [Hash]
      def user_configured_overrides
        overrides = Gitlab.config.cron_jobs.to_h
        overrides.delete('poll_interval')

        Gitlab.ee do
          overrides.merge!(Gitlab.config.ee_cron_jobs.to_h) if Gitlab.config.key?('ee_cron_jobs')
        end

        overrides
      end

      # Appends {#timezone_override} to each job's cron string in place.
      # Skips and logs a warning if {#timezone_override} is not a valid IANA timezone.
      #
      # @param jobs [Hash{String => Hash}]
      def apply_timezone_override(jobs)
        tz = timezone_override
        return if tz.nil? || tz.to_s.empty?

        validated_tz = validate_timezone(tz)
        return unless validated_tz

        jobs.each_value do |job|
          cron = job['cron']
          next if cron.nil? || cron.to_s.empty?

          job['cron'] = append_timezone(cron, validated_tz)
        end
      end

      # Returns the canonical IANA name for +tz+, or nil and logs a warning if invalid.
      # Only TZInfo identifiers are accepted (e.g. "America/Chicago");
      # ActiveSupport aliases (e.g. "Pacific Time (US & Canada)") are not.
      #
      # @param tz [String]
      # @return [String, nil]
      def validate_timezone(tz)
        ActiveSupport::TimeZone.find_tzinfo(tz)
        tz
      rescue TZInfo::InvalidTimezoneIdentifier
        Gitlab::AppLogger.warn(
          "cron_jobs: invalid timezone_override #{tz.inspect} — timezone override will be ignored"
        )
        nil
      end

      # sidekiq-cron parses TZ from the trailing token of the cron string via Fugit
      # (e.g. "0 22 * * 1-5 America/Chicago"). A standard cron expression has 5 fields;
      # anything beyond 5 tokens is treated as an already-suffixed timezone and left alone.
      #
      # @param cron [String]
      # @param tz [String]
      # @return [String]
      def append_timezone(cron, tz)
        return cron if tz.nil? || cron.to_s.split.length > 5

        "#{cron} #{tz}"
      end
    end
  end
end
