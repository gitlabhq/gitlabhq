# frozen_string_literal: true

module Ci
  module RetentionPolicies
    class ProjectsCleanupQueue
      include Singleton

      LAST_QUEUED_KEY = 'ci_old_pipelines_removal_last_processed_project_id{}'
      REDIS_EXPIRATION_TIME = 2.hours.to_i
      QUEUE_KEY = 'ci_old_pipelines_removal_project_ids_queue{}'
      PROJECTS_LIMIT = 2_500

      def size
        with_redis do |redis|
          redis.llen(QUEUE_KEY).to_i
        end
      end

      def max_size
        PROJECTS_LIMIT
      end

      def enqueue_projects!
        fetch_limit = max_size - size
        return unless fetch_limit > 0

        project_ids = fetch_next_project_ids(fetch_limit)

        enqueue_and_track_last!(project_ids)
        # Since we order projects by ID and we take the next N projects,
        # if we reach the end of the list we start again.
        restart! if project_ids.empty? || project_ids.size < fetch_limit
      end

      def enqueue!(project)
        with_redis do |redis|
          redis.rpush(QUEUE_KEY, [project.id])
        end
      end

      def fetch_next_project_id!
        with_redis do |redis|
          redis.lpop(QUEUE_KEY).to_i
        end
      end

      def last_queued_project_id
        with_redis do |redis|
          redis.get(LAST_QUEUED_KEY).to_i
        end
      end

      def list_all
        with_redis do |redis|
          redis.lrange(QUEUE_KEY, 0, -1)
        end
      end

      private

      ##
      # Add new work to the queue and keep track of last item.
      #
      # existing[1, 2, 3] << new[4, 5, 6] ==> [1, 2, 3, 4, 5, 6]
      # last: 6
      def enqueue_and_track_last!(project_ids)
        return if project_ids.empty?

        with_redis do |redis|
          redis.pipelined do |pipeline|
            pipeline.rpush(QUEUE_KEY, project_ids)
            pipeline.set(LAST_QUEUED_KEY, project_ids.last, ex: REDIS_EXPIRATION_TIME)
          end
        end
      end

      def fetch_next_project_ids(limit)
        # To avoid fetching again the already queued ID, we increment
        # the value if non-zero.
        last_id = last_queued_project_id
        next_project_id_to_fetch = last_id == 0 ? 0 : last_id + 1

        ProjectCiCdSetting
          .configured_to_delete_old_pipelines
          .for_project(next_project_id_to_fetch..)
          .order_project_id_asc
          .pluck_project_id(limit)
      end

      def restart!
        with_redis do |redis|
          redis.del(LAST_QUEUED_KEY)
        end
      end

      def with_redis(&)
        Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- not AR
      end
    end
  end
end
