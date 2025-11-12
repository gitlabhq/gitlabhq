# frozen_string_literal: true

module Ci
  module RetentionPolicies
    # Cache the last deletion timestamp for pipeline cleanup operations per project and status.
    #
    # This class provides Redis-based storage for caching the last processed pipeline's created_at timestamp
    # for a given project grouped by status to avoid querying of old data, thereby improving performance.
    #
    # The Redis key includes both project ID and the project's pipeline retention
    # setting to ensure cache invalidation when retention policies change.
    #
    # @example Cache timestamps for multiple statuses
    #   PipelineDeletionCutoffCache.new(project: Project.first).write(
    #     values: {
    #       'success' => Time.current,
    #       'failed' => 1.hour.ago,
    #       'canceled' => 2.hours.ago
    #     }
    #   )
    #
    # @example Clear all timestamps for a project
    #   PipelineDeletionCutoffCache.new(project: Project.first).clear
    #
    # @example Read all cached timestamps for a project
    #   PipelineDeletionCutoffCache.new(project: Project.first).read
    #   # => {"success" => 2024-11-05 12:00:00 UTC, "failed" => 2024-11-05 11:00:00 UTC}
    #
    class PipelineDeletionCutoffCache
      REDIS_KEY_FMT = 'ci_old_pipelines_removal_cache_%{config}:{%{project_id}}'
      REDIS_KEY_TTL = 1.week.to_i # to prevent stale data

      def initialize(project:)
        @project = project
      end

      # @param values [Hash<String, Time>] Hash of status => timestamp pairs
      # @return [String, nil] 'OK' if successful, nil otherwise
      def write(values)
        return if values.empty?

        with_redis do |redis|
          redis.set(key, values.compact.to_json, ex: REDIS_KEY_TTL)
        end
      end

      # @return [Hash<String, Time>] Hash of status => timestamp pairs, empty hash if no data
      def read
        with_redis do |redis|
          Gitlab::Json.parse(redis.get(key))
                      .to_h
                      .transform_values { |timestamp| Time.iso8601(timestamp) }
        end
      rescue JSON::ParserError
        {}
      end

      def clear
        with_redis do |redis|
          redis.del(key)
        end
      end

      private

      attr_reader :project

      def config
        project.ci_delete_pipelines_in_seconds
      end

      def key
        format(REDIS_KEY_FMT, project_id: project.id, config: config)
      end

      def with_redis(&)
        Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- not AR
      end
    end
  end
end
