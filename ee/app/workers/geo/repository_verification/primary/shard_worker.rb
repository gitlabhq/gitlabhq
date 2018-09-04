module Geo
  module RepositoryVerification
    module Primary
      class ShardWorker < Geo::Scheduler::Primary::SchedulerWorker
        sidekiq_options retry: false

        attr_accessor :shard_name

        def perform(shard_name)
          @shard_name = shard_name

          return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

          super()
        end

        private

        def worker_metadata
          { shard: shard_name }
        end

        # We need a custom key here since we are running one worker per shard
        def lease_key
          @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
        end

        def max_capacity
          current_node.verification_max_capacity
        end

        def schedule_job(project_id)
          job_id = Geo::RepositoryVerification::Primary::SingleWorker.perform_async(project_id)

          { id: project_id, job_id: job_id } if job_id
        end

        def finder
          @finder ||= Geo::RepositoryVerificationFinder.new(shard_name: shard_name)
        end

        def load_pending_resources
          resources = find_unverified_project_ids(batch_size: db_retrieve_batch_size)
          remaining_capacity = db_retrieve_batch_size - resources.size
          return resources if remaining_capacity.zero?

          resources += find_outdated_project_ids(batch_size: remaining_capacity)
          remaining_capacity = db_retrieve_batch_size - resources.size
          return resources if remaining_capacity.zero?

          resources + find_failed_project_ids(batch_size: remaining_capacity)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_unverified_project_ids(batch_size:)
          finder.find_unverified_projects(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def find_outdated_project_ids(batch_size:)
          finder.find_outdated_projects(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def find_failed_project_ids(batch_size:)
          repositories_ids = find_failed_repositories_ids(batch_size: batch_size)
          wiki_ids = find_failed_wiki_ids(batch_size: batch_size)

          take_batch(repositories_ids, wiki_ids, batch_size: batch_size)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_failed_repositories_ids(batch_size:)
          finder.find_failed_repositories(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def find_failed_wiki_ids(batch_size:)
          finder.find_failed_wikis(batch_size: batch_size).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
