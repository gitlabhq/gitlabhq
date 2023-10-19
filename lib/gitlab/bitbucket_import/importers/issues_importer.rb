# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class IssuesImporter
        include ParallelScheduling

        def execute
          log_info(import_stage: 'import_issues', message: 'importing issues')

          issues = client.issues(project.import_source)

          labels = build_labels_hash

          issues.each do |issue|
            job_waiter.jobs_remaining += 1

            next if already_enqueued?(issue)

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            issue_hash = issue.to_hash.merge({ issue_type_id: default_issue_type_id, label_id: labels[issue.kind] })
            sidekiq_worker_class.perform_in(job_delay, project.id, issue_hash, job_waiter.key)

            mark_as_enqueued(issue)
          end

          job_waiter
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        private

        def sidekiq_worker_class
          ImportIssueWorker
        end

        def collection_method
          :issues
        end

        def id_for_already_enqueued_cache(object)
          object.iid
        end

        def default_issue_type_id
          ::WorkItems::Type.default_issue_type.id
        end

        def build_labels_hash
          labels = {}
          project.labels.each { |l| labels[l.title.to_s] = l.id }
          labels
        end
      end
    end
  end
end
