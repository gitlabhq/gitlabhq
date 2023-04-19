# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is used to update the code_suggestions column
    # to true for the namespace_settings table.
    class UpdateCodeSuggestionsForNamespaceSettings < BatchedMigrationJob
      operation_name :update_code_suggestions_to_true
      feature_category :code_suggestions

      def perform
        each_sub_batch do |sub_batch|
          update_code_suggestions_to_true(sub_batch)
        end
      end

      private

      def update_code_suggestions_to_true(relation)
        relation.update_all(code_suggestions: true)
      end
    end
  end
end
