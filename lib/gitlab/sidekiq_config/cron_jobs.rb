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
        def config
          @config ||= new.load
        end

        def reset!
          @config = nil
        end
      end

      def load
        jobs = load_schedule_files(schedule_paths)
        apply_user_overrides(jobs)
        jobs
      end

      private

      def schedule_paths
        paths = [SCHEDULE_PATH]
        paths << EE_SCHEDULE_PATH if Gitlab.ee?
        paths << SAAS_SCHEDULE_PATH if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- SaaS schedule file gating
        paths << JH_SCHEDULE_PATH if Gitlab.jh?
        paths
      end

      def load_schedule_files(paths)
        paths.each_with_object({}) do |path, jobs|
          load_schedule_file(path).each do |name, config|
            jobs[name.to_s] = jobs.fetch(name.to_s, {}).merge(config.stringify_keys)
          end
        end
      end

      def load_schedule_file(path)
        return {} unless File.exist?(path)

        YAML.safe_load_file(path) || {}
      end

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

      def user_configured_overrides
        overrides = Gitlab.config.cron_jobs.to_h
        overrides.delete('poll_interval')

        Gitlab.ee do
          overrides.merge!(Gitlab.config.ee_cron_jobs.to_h) if Gitlab.config.key?('ee_cron_jobs')
        end

        overrides
      end
    end
  end
end
