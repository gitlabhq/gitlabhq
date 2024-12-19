# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssueSerializer
      attr_reader :jira_issue, :project, :import_owner_id, :params, :formatter

      def initialize(project, jira_issue, import_owner_id, work_item_type, params = {})
        @jira_issue = jira_issue
        @project = project
        @import_owner_id = import_owner_id
        @work_item_type = work_item_type
        @params = params
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        {
          iid: params[:iid],
          project_id: project.id,
          namespace_id: project.project_namespace_id,
          description: description,
          title: title,
          state_id: map_status(jira_issue.status.statusCategory),
          updated_at: jira_issue.updated,
          created_at: jira_issue.created,
          author_id: reporter,
          assignee_ids: assignees,
          label_ids: label_ids,
          correct_work_item_type_id: @work_item_type.correct_id
        }
      end

      private

      def title
        "[#{jira_issue.key}] #{jira_issue.summary}"
      end

      def description
        body = []
        body << jira_issue.description
        body << MetadataCollector.new(jira_issue).execute

        body.join
      end

      def map_status(jira_status_category)
        case jira_status_category["key"].downcase
        when 'done'
          ::Issuable::STATE_ID_MAP[:closed]
        else
          ::Issuable::STATE_ID_MAP[:opened]
        end
      end

      def map_user_id(jira_user)
        jira_user_identifier = jira_user&.dig('accountId') || jira_user&.dig('key')
        return unless jira_user_identifier

        Gitlab::JiraImport.get_user_mapping(project.id, jira_user_identifier)
      end

      def reporter
        map_user_id(jira_issue.reporter&.attrs) || import_owner_id
      end

      def assignees
        found_user_id = map_user_id(jira_issue.assignee.try(:attrs))

        return unless found_user_id

        [found_user_id]
      end

      # We already create labels in Gitlab::JiraImport::LabelsImporter stage but
      # there is a possibility it may fail or
      # new labels were created on the Jira in the meantime
      def label_ids
        return if jira_issue.fields['labels'].blank?

        Gitlab::JiraImport::HandleLabelsService.new(project, jira_issue.fields['labels']).execute
      end

      def logger
        @logger ||= ::Import::Framework::Logger.build
      end
    end
  end
end
