# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssueSerializer
      attr_reader :jira_issue, :project, :import_owner_id, :params, :formatter

      def initialize(project, jira_issue, import_owner_id, params = {})
        @jira_issue = jira_issue
        @project = project
        @import_owner_id = import_owner_id
        @params = params
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        {
          iid: params[:iid],
          project_id: project.id,
          description: description,
          title: title,
          state_id: map_status(jira_issue.status.statusCategory),
          updated_at: jira_issue.updated,
          created_at: jira_issue.created,
          author_id: reporter,
          assignee_ids: assignees,
          label_ids: label_ids
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
          Issuable::STATE_ID_MAP[:closed]
        else
          Issuable::STATE_ID_MAP[:opened]
        end
      end

      def map_user_id(email)
        return unless email

        # We also include emails that are not yet confirmed
        users = User.by_any_email(email).to_a

        # this event should never happen but we should log it in case we have invalid data
        log_user_mapping_message('Multiple users found for an email address', email) if users.count > 1

        user = users.first

        unless project.project_member(user)
          log_user_mapping_message('Jira user not found', email)

          return
        end

        user.id
      end

      def reporter
        map_user_id(jira_issue&.reporter&.emailAddress) || import_owner_id
      end

      def assignees
        found_user_id = map_user_id(jira_issue&.assignee&.emailAddress)

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
        @logger ||= Gitlab::Import::Logger.build
      end

      def log_user_mapping_message(message, email)
        logger.info(
          project_id: project.id,
          project_path: project.full_path,
          user_email: email,
          message: message
        )
      end
    end
  end
end
