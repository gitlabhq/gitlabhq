module Geo
  module RepositoryVerification
    module Secondary
      class SchedulerWorker < Geo::Scheduler::SecondaryWorker
        include CronjobQueue

        MAX_CAPACITY = 1000

        def perform
          return unless Feature.enabled?('geo_repository_verification')

          super
        end

        private

        def max_capacity
          MAX_CAPACITY
        end

        def load_pending_resources
          finder.find_registries_to_verify(batch_size: db_retrieve_batch_size)
                .pluck(:id)
        end

        def schedule_job(registry_id)
          job_id = Geo::RepositoryVerification::Secondary::SingleWorker.perform_async(registry_id)

          { id: registry_id, job_id: job_id } if job_id
        end

        def finder
          @finder ||= Geo::ProjectRegistryFinder.new
        end
      end
    end
  end
end
