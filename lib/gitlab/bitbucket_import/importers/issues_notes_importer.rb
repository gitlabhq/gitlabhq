# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class IssuesNotesImporter
        include ParallelScheduling

        MAX_IID_CACHE_KEY = 'bitbucket-importer/max-iid/%{project_id}/issues'

        def execute
          source_issues.find_each do |issue|
            job_waiter.jobs_remaining += 1

            next if already_enqueued?(issue)

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_class.perform_in(job_delay, project.id, { iid: issue.iid }, job_waiter.key)

            mark_as_enqueued(issue)
          end

          job_waiter
        rescue StandardError => e
          track_import_failure!(project, exception: e)
          job_waiter
        end

        private

        attr_reader :project

        def sidekiq_class
          ImportIssueNotesWorker
        end

        def id_for_already_enqueued_cache(object)
          object.iid
        end

        def source_issues
          max_iid = Gitlab::Cache::Import::Caching.read(format(MAX_IID_CACHE_KEY, project_id: project.id))
          scope = project.issues
          scope = scope.where(iid: ..max_iid.to_i) if max_iid.present? # rubocop:disable CodeReuse/ActiveRecord -- simple IID boundary filter
          scope
        end

        def collection_method
          :issues_notes
        end
      end
    end
  end
end
