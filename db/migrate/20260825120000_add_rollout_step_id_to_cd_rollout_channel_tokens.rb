# frozen_string_literal: true

class AddRolloutStepIdToCdRolloutChannelTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  INDEX_NAME = 'index_cd_rollout_channel_tokens_on_rollout_step_id'

  def up
    add_column :cd_rollout_channel_tokens, :rollout_step_id, :bigint, if_not_exists: true
    add_concurrent_index :cd_rollout_channel_tokens, :rollout_step_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_rollout_channel_tokens, INDEX_NAME
    remove_column :cd_rollout_channel_tokens, :rollout_step_id, if_exists: true
  end
end
