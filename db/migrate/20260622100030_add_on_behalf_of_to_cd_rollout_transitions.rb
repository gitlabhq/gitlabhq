# frozen_string_literal: true

class AddOnBehalfOfToCdRolloutTransitions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_column :cd_rollout_transitions, :on_behalf_of, :text, if_not_exists: true
    add_text_limit :cd_rollout_transitions, :on_behalf_of, 255
  end

  def down
    remove_column :cd_rollout_transitions, :on_behalf_of, if_exists: true
  end
end
