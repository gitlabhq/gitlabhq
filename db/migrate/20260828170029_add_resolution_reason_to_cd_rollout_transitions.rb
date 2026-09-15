# frozen_string_literal: true

class AddResolutionReasonToCdRolloutTransitions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  def up
    add_column :cd_rollout_transitions, :resolution_reason, :text, if_not_exists: true
    add_text_limit :cd_rollout_transitions, :resolution_reason, 2000
  end

  def down
    remove_column :cd_rollout_transitions, :resolution_reason, if_exists: true
  end
end
