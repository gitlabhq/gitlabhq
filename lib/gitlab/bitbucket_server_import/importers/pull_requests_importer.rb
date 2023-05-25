# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestsImporter
        include ParallelScheduling

        def execute
          page = 1

          loop do
            log_info(
              import_stage: 'import_pull_requests', message: "importing page #{page} using batch-size #{BATCH_SIZE}"
            )

            pull_requests = client.pull_requests(
              project_key, repository_slug, page_offset: page, limit: BATCH_SIZE
            ).to_a

            break if pull_requests.empty?

            pull_requests.each do |pull_request|
              # Needs to come before `already_processed?` as `jobs_remaining` resets to zero when the job restarts and
              # jobs_remaining needs to be the total amount of enqueued jobs
              job_waiter.jobs_remaining += 1

              next if already_processed?(pull_request)

              job_delay = calculate_job_delay(job_waiter.jobs_remaining)

              sidekiq_worker_class.perform_in(job_delay, project.id, pull_request.to_hash, job_waiter.key)

              mark_as_processed(pull_request)
            end

            page += 1
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

        def id_for_already_processed_cache(object)
          object.iid
        end
      end
    end
  end
end
