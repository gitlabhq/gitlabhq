# frozen_string_literal: true

module Gitlab
  module Issues
    module Rebalancing
      class State
        REDIS_KEY_PREFIX = "gitlab:issues-position-rebalances"
        CONCURRENT_RUNNING_REBALANCES_KEY = "#{REDIS_KEY_PREFIX}:running_rebalances"
        RECENTLY_FINISHED_REBALANCE_PREFIX = "#{REDIS_KEY_PREFIX}:recently_finished"

        REDIS_EXPIRY_TIME = 10.days
        MAX_NUMBER_OF_CONCURRENT_REBALANCES = 5
        NAMESPACE = 1
        PROJECT = 2

        def initialize(root_namespace, projects)
          @root_namespace = root_namespace
          @projects = projects
          @rebalanced_container_type = @root_namespace.is_a?(Group) ? NAMESPACE : PROJECT
          @rebalanced_container_id = @rebalanced_container_type == NAMESPACE ? @root_namespace.id : projects.take.id # rubocop:disable CodeReuse/ActiveRecord
        end

        def track_new_running_rebalance
          with_redis do |redis|
            redis.multi do |multi|
              # we trigger re-balance for namespaces(groups) or specific user project
              value = "#{rebalanced_container_type}/#{rebalanced_container_id}"
              multi.sadd?(CONCURRENT_RUNNING_REBALANCES_KEY, value)
              multi.expire(CONCURRENT_RUNNING_REBALANCES_KEY, REDIS_EXPIRY_TIME)
            end
          end
        end

        def concurrent_running_rebalances_count
          with_redis { |redis| redis.scard(CONCURRENT_RUNNING_REBALANCES_KEY).to_i }
        end

        def rebalance_in_progress?
          is_running = case rebalanced_container_type
                       when NAMESPACE
                         namespace_ids = self.class.current_rebalancing_containers.filter_map { |string| string.split("#{NAMESPACE}/").second.to_i }
                         namespace_ids.include?(root_namespace.id)
                       when PROJECT
                         project_ids = self.class.current_rebalancing_containers.filter_map { |string| string.split("#{PROJECT}/").second.to_i }
                         project_ids.include?(projects.take.id) # rubocop:disable CodeReuse/ActiveRecord
                       else
                         false
                       end

          refresh_keys_expiration if is_running

          is_running
        end

        def can_start_rebalance?
          rebalance_in_progress? || concurrent_rebalance_within_limit?
        end

        def cache_issue_ids(issue_ids)
          with_redis do |redis|
            values = issue_ids.map { |issue| [issue.relative_position, issue.id] }

            redis.multi do |multi|
              multi.zadd(issue_ids_key, values) unless values.blank?
              multi.expire(issue_ids_key, REDIS_EXPIRY_TIME)
            end
          end
        end

        def get_cached_issue_ids(index, limit)
          with_redis do |redis|
            redis.zrange(issue_ids_key, index, index + limit - 1)
          end
        end

        def cache_current_index(index)
          with_redis { |redis| redis.set(current_index_key, index, ex: REDIS_EXPIRY_TIME) }
        end

        def get_current_index
          with_redis { |redis| redis.get(current_index_key).to_i }
        end

        def cache_current_project_id(project_id)
          with_redis { |redis| redis.set(current_project_key, project_id, ex: REDIS_EXPIRY_TIME) }
        end

        def get_current_project_id
          with_redis { |redis| redis.get(current_project_key) }
        end

        def issue_count
          @issue_count ||= with_redis { |redis| redis.zcard(issue_ids_key) }
        end

        def remove_current_project_id_cache
          with_redis { |redis| redis.del(current_project_key) }
        end

        def refresh_keys_expiration
          with_redis do |redis|
            Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
              redis.pipelined do |pipeline|
                pipeline.expire(issue_ids_key, REDIS_EXPIRY_TIME)
                pipeline.expire(current_index_key, REDIS_EXPIRY_TIME)
                pipeline.expire(current_project_key, REDIS_EXPIRY_TIME)
                pipeline.expire(CONCURRENT_RUNNING_REBALANCES_KEY, REDIS_EXPIRY_TIME)
              end
            end
          end
        end

        def cleanup_cache
          value = "#{rebalanced_container_type}/#{rebalanced_container_id}"

          # The clean up is done sequentially to be compatible with Redis Cluster
          # Do not use a pipeline as it fans-out in a Redis-Cluster setting and forego ordering guarantees
          with_redis do |redis|
            # srem followed by .del(issue_ids_key) to ensure that any subsequent redis errors would
            # result in a no-op job retry since current_index_key still exists
            redis.srem?(CONCURRENT_RUNNING_REBALANCES_KEY, value)
            redis.del(issue_ids_key)

            # delete current_index_key to ensure that subsequent redis errors would
            # result in a fresh job retry
            redis.del(current_index_key)

            # setting recently_finished_key last after job details is cleaned up
            redis.set(self.class.recently_finished_key(rebalanced_container_type, rebalanced_container_id), true, ex: 1.hour)
          end
        end

        def self.rebalance_recently_finished?(project_id, namespace_id)
          container_id = project_id || namespace_id
          container_type = project_id.present? ? PROJECT : NAMESPACE

          Gitlab::Redis::SharedState.with { |redis| redis.get(recently_finished_key(container_type, container_id)) }
        end

        def self.fetch_rebalancing_groups_and_projects
          namespace_ids = []
          project_ids = []

          current_rebalancing_containers.each do |string|
            container_type, container_id = string.split('/', 2).map(&:to_i)

            case container_type
            when NAMESPACE
              namespace_ids << container_id
            when PROJECT
              project_ids << container_id
            end
          end

          [namespace_ids, project_ids]
        end

        private

        def self.current_rebalancing_containers
          Gitlab::Redis::SharedState.with { |redis| redis.smembers(CONCURRENT_RUNNING_REBALANCES_KEY) }
        end

        attr_accessor :root_namespace, :projects, :rebalanced_container_type, :rebalanced_container_id

        def concurrent_rebalance_within_limit?
          concurrent_running_rebalances_count <= MAX_NUMBER_OF_CONCURRENT_REBALANCES
        end

        def issue_ids_key
          "#{REDIS_KEY_PREFIX}:#{root_namespace.id}"
        end

        def current_index_key
          "#{issue_ids_key}:current_index"
        end

        def current_project_key
          "#{issue_ids_key}:current_project_id"
        end

        def self.recently_finished_key(container_type, container_id)
          "#{RECENTLY_FINISHED_REBALANCE_PREFIX}:#{container_type}:#{container_id}"
        end

        def with_redis(&blk)
          Gitlab::Redis::SharedState.with(&blk) # rubocop: disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
