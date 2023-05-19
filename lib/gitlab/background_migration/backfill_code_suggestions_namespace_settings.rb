# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class sets default `code_suggestions` values on the namespace_settings table.
    # For group namespace, set this to enabled.
    # For user namespace, set this to disabled.
    class BackfillCodeSuggestionsNamespaceSettings < BatchedMigrationJob
      feature_category :code_suggestions
      operation_name :update_all

      TYPE_VALUE_PAIRS = [
        { type: 'Group', value: true },
        { type: 'User', value: false }
      ].freeze

      NAMESPACES_JOIN = <<~SQL
        INNER JOIN namespaces
        ON namespaces.id = namespace_settings.namespace_id
      SQL

      def perform
        TYPE_VALUE_PAIRS.each do |pair|
          each_sub_batch do |sub_batch|
            sub_batch.joins(NAMESPACES_JOIN)
              .where(namespaces: { type: pair[:type] })
              .update_all(code_suggestions: pair[:value])
          end
        end
      end
    end
  end
end
