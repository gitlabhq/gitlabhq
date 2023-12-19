# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class PullRequestsNotesImporter
        include ParallelScheduling

        def execute
          project.merge_requests.find_each do |merge_request|
            job_waiter.jobs_remaining += 1

            next if already_enqueued?(merge_request)

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_worker_class.perform_in(job_delay, project.id, { iid: merge_request.iid }, job_waiter.key)

            mark_as_enqueued(merge_request)
          end

          job_waiter
        rescue StandardError => e
          track_import_failure!(project, exception: e)
          job_waiter
        end

        private

        attr_reader :project

        def sidekiq_worker_class
          ImportPullRequestNotesWorker
        end

        def id_for_already_enqueued_cache(object)
          object.iid
        end

        def collection_method
          :merge_requests_notes
        end
      end
    end
  end
end
