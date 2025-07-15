# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class PullRequestsImporter
        include ParallelScheduling

        def execute
          log_info(import_stage: 'import_pull_requests', message: 'importing pull requests')

          each_object_to_import do |object|
            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_worker_class.perform_in(job_delay, project.id, object.to_hash, job_waiter.key)
          end

          job_waiter
        end

        private

        def sidekiq_worker_class
          ImportPullRequestWorker
        end

        def collection_method
          :pull_requests
        end

        def collection_options
          { raw: true }
        end

        def representation_type
          :pull_request
        end

        def id_for_already_enqueued_cache(object)
          object[:iid]
        end

        # To avoid overloading Gitaly, we use a smaller limit for pull requests than the one defined in the
        # application settings.
        def concurrent_import_jobs_limit
          100
        end
      end
    end
  end
end
