# frozen_string_literal: true

module Gitlab
  module SidekiqLimits
    HIGH_DB_DURATION_WORKERS = %w[
      PipelineProcessWorker
      Ci::BuildFinishedWorker
      PostReceive
      UpdateMergeRequestsWorker
      NewMergeRequestWorker
      WebHooks::LogExecutionWorker
      ProcessCommitWorker
      NewNoteWorker
      MergeRequestMergeabilityCheckWorker
      RunPipelineScheduleWorker
    ].freeze

    CI_HIGH_DB_DURATION_WORKERS = %w[
      PipelineProcessWorker
      Ci::BuildFinishedWorker
      Ci::ArchiveTraceWorker
      Ci::BuildTraceChunkFlushWorker
      Ci::InitialPipelineProcessWorker
      Ci::CreateDownstreamPipelineWorker
      RunPipelineScheduleWorker
      PostReceive
      Ci::UnlockPipelinesInQueueWorker
      Ci::Refs::UnlockPreviousPipelinesWorker
    ].freeze

    DEFAULT_SIDEKIQ_LIMITS = {
      main_db_duration_limit_per_worker: {
        resource_key: 'db_main_duration_s',
        metadata: {
          db_config_name: 'main'
        },
        scopes: [
          'worker_name'
        ],
        rules: [
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("worker_name=#{HIGH_DB_DURATION_WORKERS.join(',')}"),
            threshold: 3000,
            interval: 60
          },
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("*"),
            threshold: 1000,
            interval: 60
          }
        ]
      },
      ci_db_duration_limit_per_worker: {
        resource_key: 'db_ci_duration_s',
        metadata: {
          db_config_name: 'ci'
        },
        scopes: [
          'worker_name'
        ],
        rules: [
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("worker_name=#{CI_HIGH_DB_DURATION_WORKERS.join(',')}"),
            threshold: 3000,
            interval: 60
          },
          {
            selector: Gitlab::SidekiqConfig::WorkerMatcher.new("*"),
            threshold: 1000,
            interval: 60
          }
        ]
      }
    }.freeze

    # name         - <String> name of the limit to be used in ApplicationRateLimiter
    # resource_key - <String> Key in SafeRequestStore which tracks a resource usage
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

        # NOTE: use hardcoded defaults in the initial phase.
        # Move to ApplicationSettings and eventually an external rate limiting service
        # through labkit.
        DEFAULT_SIDEKIQ_LIMITS.each do |name, l|
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
    end
  end
end
