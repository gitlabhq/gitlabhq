# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class PullRequestsNotesImporter
        include ParallelScheduling

        MAX_IID_CACHE_KEY = 'bitbucket-importer/max-iid/%{project_id}/merge_requests'

        def execute
          source_merge_requests.find_each do |merge_request|
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

        def source_merge_requests
          max_iid = Gitlab::Cache::Import::Caching.read(format(MAX_IID_CACHE_KEY, project_id: project.id))
          scope = project.merge_requests
          scope = scope.where(iid: ..max_iid.to_i) if max_iid.present? # rubocop:disable CodeReuse/ActiveRecord -- simple IID boundary filter
          scope
        end

        def collection_method
          :merge_requests_notes
        end
      end
    end
  end
end
