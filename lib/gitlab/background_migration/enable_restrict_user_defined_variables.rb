# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration is backwards compatible and no behavior change is expected.
    #
    # The settings `restrict_user_defined_variables` and `pipeline_variables_minimum_override_role` are
    # expected to work together. We only consider `pipeline_variables_minimum_override_role` when
    # `restrict_user_defined_variables: true`:
    #   * When `restrict_user_defined_variables: false` (default behavior at the time of this migration)
    #     we allow Developer+ roles to use pipeline variables in CI pipelines.
    #   * When `restrict_user_defined_variables: true` we allow the roles base on the setting
    #     `pipeline_variables_minimum_override_role` (developer, maintainer, owner, no_one_allowed).
    #
    # The goal of this migration is to enable `restrict_user_defined_variables` everywhere so we can
    # rely solely on `pipeline_variables_minimum_override_role` as SSoT setting. In order to do that
    # we need to set `pipeline_variables_minimum_override_role: :developer` to maintain backwards
    # compatibility.
    class EnableRestrictUserDefinedVariables < BatchedMigrationJob
      operation_name :enable_restrict_user_defined_variables
      feature_category :ci_variables

      DEVELOPER_ROLE = 2

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(restrict_user_defined_variables: false)
            .update_all(
              restrict_user_defined_variables: true,
              pipeline_variables_minimum_override_role: DEVELOPER_ROLE)
        end
      end
    end
  end
end
