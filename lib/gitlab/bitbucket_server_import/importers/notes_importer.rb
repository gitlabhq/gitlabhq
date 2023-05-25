# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class NotesImporter
        include ParallelScheduling

        def execute
          project.merge_requests.find_each do |merge_request|
            # Needs to come before `already_processed?` as `jobs_remaining` resets to zero when the job restarts and
            # jobs_remaining needs to be the total amount of enqueued jobs
            job_waiter.jobs_remaining += 1

            next if already_processed?(merge_request)

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_worker_class.perform_in(job_delay, project.id, { iid: merge_request.iid }, job_waiter.key)

            mark_as_processed(merge_request)
          end

          job_waiter
        end

        private

        attr_reader :project

        def sidekiq_worker_class
          ImportPullRequestNotesWorker
        end

        def id_for_already_processed_cache(merge_request)
          merge_request.iid
        end

        def collection_method
          :notes
        end
      end
    end
  end
end
