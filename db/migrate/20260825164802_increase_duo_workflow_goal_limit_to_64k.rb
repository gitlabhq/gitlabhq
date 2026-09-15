# frozen_string_literal: true

class IncreaseDuoWorkflowGoalLimitTo64k < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  def up
    # rubocop:disable Migration/PreventLargeBlobInDatabase -- The goal carries the
    # flow's full prompt context (e.g. MR discussion threads), which legitimately
    # exceeds the previous 16,384 limit. A model-level bytesize validation (127 KiB)
    # keeps the DUO_WORKFLOW_GOAL env var under MAX_ARG_STRLEN.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/616260
    add_text_limit :duo_workflows_workflows, :goal, 65_536,
      constraint_name: check_constraint_name(:duo_workflows_workflows, :goal, 'max_length_64K')
    # rubocop:enable Migration/PreventLargeBlobInDatabase
    remove_text_limit :duo_workflows_workflows, :goal,
      constraint_name: check_constraint_name(:duo_workflows_workflows, :goal, 'max_length_16K')
  end

  def down
    # no-op: rows with goal longer than 16,384 chars may exist once the new limit
    # is in use, so re-adding the old constraint would fail validation. See
    # https://docs.gitlab.com/development/database/strings_and_the_text_data_type/#increasing-a-text-limit-constraint-on-an-existing-column
  end
end
