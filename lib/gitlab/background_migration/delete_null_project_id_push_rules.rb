# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteNullProjectIdPushRules < BatchedMigrationJob
      operation_name :delete_null_project_id_push_rules
      feature_category :source_code_management
      scope_to ->(relation) { relation.where(project_id: nil) } # rubocop:disable Database/AvoidScopeTo -- index_push_rules_on_project_id exists

      def perform
        each_sub_batch(&:delete_all)
      end
    end
  end
end
