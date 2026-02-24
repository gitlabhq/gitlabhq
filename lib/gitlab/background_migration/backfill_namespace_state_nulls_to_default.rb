# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillNamespaceStateNullsToDefault < BatchedMigrationJob
      cursor :id

      operation_name :namespace_state_nulls_to_default
      feature_category :groups_and_projects

      ANCESTOR_INHERITED_STATE = 0

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(state: nil).update_all(state: ANCESTOR_INHERITED_STATE)
        end
      end
    end
  end
end
