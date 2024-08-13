# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Remove organization_id from project snippets
    # their organization_id will be calculated from the project relation
    class NullifyOrganizationIdForSnippets < BatchedMigrationJob
      feature_category :source_code_management
      operation_name :nullify_organization_id_for_snippets

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(type: 'ProjectSnippet').update_all(organization_id: nil)
        end
      end
    end
  end
end
