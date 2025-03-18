# frozen_string_literal: true

class IncreaseDuoWorkflowEventsMessageLimit < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.10'

  def up
    add_text_limit :duo_workflows_events, :message, 4096,
      constraint_name: check_constraint_name(:duo_workflows_events, :message, 'max_length_4K')
    remove_text_limit :duo_workflows_events, :message,
      constraint_name: check_constraint_name(:duo_workflows_events, :message, 'max_length')
  end

  def down
    # no-op: Danger of failing if there are records with length(message) > 255
  end
end
