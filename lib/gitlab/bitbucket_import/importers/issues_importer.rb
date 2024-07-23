# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class IssuesImporter
        include ParallelScheduling

        def execute
          return job_waiter unless repo.issues_enabled?

          log_info(import_stage: 'import_issues', message: 'importing issues')

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
          labels = build_labels_hash

          is_first = true
          each_object_to_import do |object|
            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            if is_first
              allocate_issues_internal_id!
              is_first = false
            end

            issue_hash = object.to_hash.merge({ issue_type_id: default_issue_type_id, label_id: labels[object[:kind]] })
            sidekiq_worker_class.perform_in(job_delay, project.id, issue_hash, job_waiter.key)
          end

          job_waiter
        end

        def non_resumable_execute
          issues = client.issues(project.import_source)

          labels = build_labels_hash

          issues.each_with_index do |issue, index|
            job_waiter.jobs_remaining += 1

            next if already_enqueued?(issue)

            allocate_issues_internal_id! if index == 0

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            issue_hash = issue.to_hash.merge({ issue_type_id: default_issue_type_id, label_id: labels[issue.kind] })
            sidekiq_worker_class.perform_in(job_delay, project.id, issue_hash, job_waiter.key)

            mark_as_enqueued(issue)
          end

          job_waiter
        rescue StandardError => e
          track_import_failure!(project, exception: e)
          job_waiter
        end

        def sidekiq_worker_class
          ImportIssueWorker
        end

        def collection_method
          :issues
        end

        def collection_options
          { raw: true }
        end

        def representation_type
          :issue
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

        def default_issue_type_id
          ::WorkItems::Type.default_issue_type.id
        end

        def allocate_issues_internal_id!
          last_bitbucket_issue = client.last_issue(repo)

          return unless last_bitbucket_issue

          Issue.track_namespace_iid!(project.project_namespace, last_bitbucket_issue.iid)
        end

        def build_labels_hash
          labels = {}
          project.labels.each { |l| labels[l.title.to_s] = l.id }
          labels
        end

        def repo
          @repo ||= client.repo(project.import_source)
        end
      end
    end
  end
end
