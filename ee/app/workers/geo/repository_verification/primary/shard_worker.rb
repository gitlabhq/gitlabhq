module Geo
  module RepositoryVerification
    module Primary
      class ShardWorker < Geo::Scheduler::Primary::SchedulerWorker
        sidekiq_options retry: false

        MAX_CAPACITY = 100

        attr_accessor :shard_name

        def perform(shard_name)
          @shard_name = shard_name

          return unless Gitlab::Geo::ShardHealthCache.healthy_shard?(shard_name)

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
          MAX_CAPACITY
        end

        def schedule_job(project_id)
          job_id = Geo::RepositoryVerification::Primary::SingleWorker.perform_async(project_id)

          { id: project_id, job_id: job_id } if job_id
        end

        def finder
          @finder ||= Geo::RepositoryVerificationFinder.new
        end

        def load_pending_resources
          resources = find_unverified_project_ids(batch_size: db_retrieve_batch_size)
          remaining_capacity = db_retrieve_batch_size - resources.size

          if remaining_capacity.zero?
            resources
          else
            resources + find_outdated_project_ids(batch_size: remaining_capacity)
          end
        end

        def find_unverified_project_ids(batch_size:)
          shard_restriction(finder.find_unverified_projects(batch_size: batch_size))
            .pluck(:id)
        end

        def find_outdated_project_ids(batch_size:)
          shard_restriction(finder.find_outdated_projects(batch_size: batch_size))
            .pluck(:id)
        end

        def shard_restriction(relation)
          relation.where(repository_storage: shard_name)
        end
      end
    end
  end
end
