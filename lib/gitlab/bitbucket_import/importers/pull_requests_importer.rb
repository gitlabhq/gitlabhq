# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class PullRequestsImporter
        include ParallelScheduling

        def execute
          bitbucket_import_resumable_worker =
            project.import_data&.data&.dig('bitbucket_import_resumable_worker')

          if bitbucket_import_resumable_worker
            resumable_execute
          else
            non_resumable_execute
          end
        end

        private

        def resumable_execute
          log_info(import_stage: 'import_pull_requests', message: 'importing pull requests')

          each_object_to_import do |object|
            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_worker_class.perform_in(job_delay, project.id, object.to_hash, job_waiter.key)
          end

          job_waiter
        end

        def non_resumable_execute
          log_info(import_stage: 'import_pull_requests', message: 'importing pull requests')

          pull_requests = client.pull_requests(project.import_source)

          pull_requests.each do |pull_request|
            job_waiter.jobs_remaining += 1

            next if already_enqueued?(pull_request)

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_worker_class.perform_in(job_delay, project.id, pull_request.to_hash, job_waiter.key)

            mark_as_enqueued(pull_request)
          end

          job_waiter
        rescue StandardError => e
          track_import_failure!(project, exception: e)
          job_waiter
        end

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
          if object.is_a?(Hash)
            # used for `resumable_execute`
            object[:iid]
          else
            # used for `non_resumable_execute`
            object.iid
          end
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
