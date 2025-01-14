# frozen_string_literal: true

module Gitlab
  module JiraImport
    class ImportIssueWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include Gitlab::JiraImport::QueueOptions
      include Gitlab::Import::DatabaseHelpers
      include Gitlab::Import::NotifyUponDeath

      loggable_arguments 3

      def perform(project_id, jira_issue_id, issue_attributes, waiter_key)
        create_issue(issue_attributes, project_id)
      rescue StandardError => ex
        # Todo: Record jira issue id(or better jira issue key),
        # so that we can report the list of failed to import issues to the user
        # see https://gitlab.com/gitlab-org/gitlab/-/issues/211653
        #
        # It's possible the project has been deleted since scheduling this
        # job. In this case we'll just skip creating the issue.
        Gitlab::ErrorTracking.track_exception(ex, project_id: project_id)
        JiraImport.increment_issue_failures(project_id)
      ensure
        # ensure we notify job waiter that the job has finished
        JobWaiter.notify(waiter_key, jid, ttl: Gitlab::Import::JOB_WAITER_TTL) if waiter_key
      end

      private

      # Necessary temporarily as new version might process jobs enqueued in old version
      def ensure_correct_work_item_type(attributes)
        return attributes unless attributes.key?('work_item_type_id')

        work_item_type = ::WorkItems::Type.find_by_correct_id_with_fallback(attributes['work_item_type_id'])

        attributes.except('work_item_type_id').merge('correct_work_item_type_id' => work_item_type&.correct_id)
      end

      def create_issue(issue_attributes, project_id)
        label_ids = issue_attributes.delete('label_ids')
        assignee_ids = issue_attributes.delete('assignee_ids')
        issue_id = insert_and_return_id(ensure_correct_work_item_type(issue_attributes), Issue)

        label_issue(project_id, issue_id, label_ids)
        assign_issue(project_id, issue_id, assignee_ids)

        issue_id
      end

      def label_issue(project_id, issue_id, label_ids)
        label_link_attrs = label_ids.to_a.map do |label_id|
          build_label_attrs(issue_id, label_id.to_i)
        end

        import_label_id = JiraImport.get_import_label_id(project_id)
        return unless import_label_id

        label_link_attrs << build_label_attrs(issue_id, import_label_id.to_i)

        ApplicationRecord.legacy_bulk_insert(LabelLink.table_name, label_link_attrs) # rubocop:disable Gitlab/BulkInsert
      end

      def assign_issue(project_id, issue_id, assignee_ids)
        return if assignee_ids.blank?

        assignee_attrs = assignee_ids.map { |user_id| { issue_id: issue_id, user_id: user_id } }

        ApplicationRecord.legacy_bulk_insert(IssueAssignee.table_name, assignee_attrs) # rubocop:disable Gitlab/BulkInsert
      end

      def build_label_attrs(issue_id, label_id)
        time = Time.current
        {
          label_id: label_id,
          target_id: issue_id,
          target_type: 'Issue',
          created_at: time,
          updated_at: time
        }
      end
    end
  end
end
