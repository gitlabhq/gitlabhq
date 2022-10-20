# frozen_string_literal: true

module Gitlab
  module JiraImport
    class HandleLabelsService
      def initialize(project, jira_labels)
        @project = project
        @jira_labels = jira_labels
      end

      def execute
        return if jira_labels.blank?

        existing_labels = LabelsFinder.new(nil, project: project, title: jira_labels)
          .execute(skip_authorization: true).select(:id, :project_id, :group_id, :type, :name)
        new_labels = create_missing_labels(existing_labels)

        label_ids = existing_labels.map(&:id)
        label_ids += new_labels if new_labels.present?
        label_ids
      end

      private

      attr_reader :project, :jira_labels

      def create_missing_labels(existing_labels)
        labels_to_create = jira_labels - existing_labels.map(&:name)
        return if labels_to_create.empty?

        new_labels_hash = labels_to_create.map do |title|
          { project_id: project.id, title: title, type: 'ProjectLabel' }
        end

        Label.insert_all(new_labels_hash).rows.flatten
      end
    end
  end
end
