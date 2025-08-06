# frozen_string_literal: true

module Gitlab
  module SidekiqLimits
    HIGH_URGENCY_DB_DURATION_THRESHOLD_SECONDS = 100_000
    DEFAULT_DB_DURATION_THRESHOLD_SECONDS = 20_000

    # Default configuration if the limits in ApplicationSetting haven't been setup
    DEFAULT_SIDEKIQ_LIMITS = {
      main_db_duration_limit_per_worker: {
        resource_key: :db_main_duration_s,
        metadata: {
          db_config_name: 'main'
        },
        scopes: [
          'worker_name'
        ],
        rules: [
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("urgency=high"),
            threshold: HIGH_URGENCY_DB_DURATION_THRESHOLD_SECONDS,
            interval: 60
          },
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("*"),
            threshold: DEFAULT_DB_DURATION_THRESHOLD_SECONDS,
            interval: 60
          }
        ]
      },
      ci_db_duration_limit_per_worker: {
        resource_key: :db_ci_duration_s,
        metadata: {
          db_config_name: 'ci'
        },
        scopes: [
          'worker_name'
        ],
        rules: [
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("urgency=high"),
            threshold: HIGH_URGENCY_DB_DURATION_THRESHOLD_SECONDS,
            interval: 60
          },
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("*"),
            threshold: DEFAULT_DB_DURATION_THRESHOLD_SECONDS,
            interval: 60
          }
        ]
      },
      sec_db_duration_limit_per_worker: {
        resource_key: :db_sec_duration_s,
        metadata: {
          db_config_name: 'sec'
        },
        scopes: [
          'worker_name'
        ],
        rules: [
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("urgency=high"),
            threshold: HIGH_URGENCY_DB_DURATION_THRESHOLD_SECONDS,
            interval: 60
          },
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("*"),
            threshold: DEFAULT_DB_DURATION_THRESHOLD_SECONDS,
            interval: 60
          }
        ]
      }
    }.freeze

    # name         - <Symbol> name of the limit to be used in ApplicationRateLimiter
    # resource_key - <Symbol> Key in SafeRequestStore which tracks a resource usage
    # scopes       - <String> Key in ApplicationContext or the worker_name
    # metadata     - <Hash> Hash containing metadata for various usage, e.g. emitting extra logs/metrics
    #                or further logic checks before throttling.
    # threshold    - <Integer> Maximum resource usage given an interval
    # interval     - <Integer> Seconds before a resource usage tracking is refreshed
    Limit = Struct.new(:name, :resource_key, :scopes, :metadata, :threshold, :interval)

    class << self
      def limits_for(worker_name)
        worker_class = worker_name.safe_constantize
        return [] if worker_class.nil?

        if worker_class.ancestors.exclude?(ApplicationWorker)
          # NOTE: for now, we exclude mailer jobs since the Gitlab::SidekiqConfig::Worker
          # expects a ApplicationWorker. We would need a new matcher type when handling
          # instance-related attributes like namespace and user id.
          return []
        end

        worker_attr = ::Gitlab::SidekiqConfig::Worker.new(worker_class, ee: false).to_yaml
        limits = []

        # NOTE: Read from ApplicationSettings and eventually move to an external rate limiting service
        # through labkit.
        raw_limits.each do |name, l|
          threshold, interval = match_rule(l[:rules], worker_attr)
          next if threshold.nil? || interval.nil?

          limits << Limit.new(
            name, l[:resource_key], l[:scopes], l[:metadata], threshold, interval
          )
        end

        limits
      end

      private

      def match_rule(rules, worker_attr)
        rule = rules.find { |rule| rule[:selector].match?(worker_attr) }
        return unless rule

        [rule[:threshold], rule[:interval]]
      end

      def limits_from_application_setting
        raw_limits = ::Gitlab::CurrentSettings.resource_usage_limits
        return unless raw_limits && raw_limits["rules"]

        raw_limits["rules"].each_with_object({}) do |rule, result|
          key = rule["name"].to_sym

          result[key] = {
            resource_key: rule["resource_key"].to_sym,
            metadata: rule["metadata"],
            scopes: rule["scopes"],
            rules: rule["rules"].map do |r|
              {
                selector: Gitlab::SidekiqConfig::WorkerMatcher.new(r["selector"]),
                threshold: r["threshold"],
                interval: r["interval"]
              }
            end
          }
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e)
        nil
      end

      def raw_limits
        limits_from_application_setting || DEFAULT_SIDEKIQ_LIMITS
      end
    end
  end
end
