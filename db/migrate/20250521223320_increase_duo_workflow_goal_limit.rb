# frozen_string_literal: true

class IncreaseDuoWorkflowGoalLimit < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_text_limit :duo_workflows_workflows, :goal, 16_384,
      constraint_name: check_constraint_name(:duo_workflows_workflows, :goal, 'max_length_16K')
    remove_text_limit :duo_workflows_workflows, :goal,
      constraint_name: check_constraint_name(:duo_workflows_workflows, :goal, 'max_length')

    add_text_limit :duo_workflows_events, :message, 16_384,
      constraint_name: check_constraint_name(:duo_workflows_events, :message, 'max_length_16K')
    remove_text_limit :duo_workflows_events, :message,
      constraint_name: check_constraint_name(:duo_workflows_events, :message, 'max_length_4K')
  end

  def down
    add_text_limit :duo_workflows_workflows, :goal, 4096,
      constraint_name: check_constraint_name(:duo_workflows_workflows, :goal, 'max_length')
    remove_text_limit :duo_workflows_workflows, :goal,
      constraint_name: check_constraint_name(:duo_workflows_workflows, :goal, 'max_length_16K')

    add_text_limit :duo_workflows_events, :message, 4096,
      constraint_name: check_constraint_name(:duo_workflows_events, :message, 'max_length_4K')
    remove_text_limit :duo_workflows_events, :message,
      constraint_name: check_constraint_name(:duo_workflows_events, :message, 'max_length_16K')
  end
end
