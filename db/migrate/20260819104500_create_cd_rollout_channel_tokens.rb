# frozen_string_literal: true

class CreateCdRolloutChannelTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  UNIQUE_INDEX_NAME = 'index_cd_rollout_channel_tokens_on_rollout_id_and_channel_name'
  ORG_INDEX_NAME = 'index_cd_rollout_channel_tokens_on_organization_id'

  def up
    create_table :cd_rollout_channel_tokens do |t|
      t.bigint :organization_id, null: false
      t.bigint :rollout_id, null: false
      t.timestamps_with_timezone null: false
      t.text :channel_name, null: false, limit: 255
      t.jsonb :token, null: false

      t.index [:rollout_id, :channel_name], unique: true, name: UNIQUE_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
    end
  end

  def down
    drop_table :cd_rollout_channel_tokens
  end
end
