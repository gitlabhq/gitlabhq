# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssueSerializer
      attr_reader :jira_issue, :project, :import_owner_id, :params, :formatter

      MAX_ADF_DEPTH = 10
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
          work_item_type_id: @work_item_type.id,
          imported_from: ::Issue::IMPORT_SOURCES[:jira]
        }
      end

      private

      def title
        "[#{jira_issue.key}] #{jira_issue.summary}"
      end

      def description
        body = []
        desc = jira_issue.fields['description']
        body << (desc.is_a?(Hash) ? convert_adf_to_markdown(desc) : desc)
        body << MetadataCollector.new(jira_issue).execute

        body.join
      end

      def convert_adf_to_markdown(adf)
        return '' if adf.blank?

        sanitized_adf = sanitize_adf(adf)
        adf_json = sanitized_adf.to_json
        filter = Banzai::Filter::JiraImport::AdfToCommonmarkFilter.new(adf_json)
        filter.call
      rescue StandardError => e
        logger.warn("Failed to convert ADF to markdown: #{e.message}")
        Gitlab::ErrorTracking.track_exception(e)
        convert_adf_to_text(adf)
      end

      def sanitize_adf(node)
        return node unless node.is_a?(Hash)

        sanitized = node.dup

        sanitized['content'] = [] if sanitized['type'] && !sanitized.key?('content')

        if sanitized['content'].is_a?(Array)
          sanitized['content'] = sanitized['content'].map { |child| sanitize_adf(child) }
        end

        sanitized
      end

      def convert_adf_to_text(adf, depth = 0)
        return '' if adf.blank? || depth > MAX_ADF_DEPTH

        adf['content']&.filter_map { |node| extract_text(node, depth + 1) }&.join("\n") || ''
      end

      def extract_text(node, depth = 0)
        return '' unless node.is_a?(Hash)
        return '' if depth > MAX_ADF_DEPTH

        node['content']&.filter_map { |n| n['text'] || extract_text(n, depth + 1) }&.join || ''
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
