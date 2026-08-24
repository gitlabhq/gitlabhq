# frozen_string_literal: true

class CreateCdRolloutWorkflowTokens < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  ROLLOUT_INDEX_NAME = 'index_cd_rollout_workflow_tokens_on_rollout_id'
  ORG_INDEX_NAME = 'index_cd_rollout_workflow_tokens_on_organization_id'

  # One row per rollout, holding the AutoFlow secrets for its workflow. Kept out of
  # cd_rollouts so reading a rollout does not read them. Both are encrypted attributes,
  # hence jsonb rather than text. token_binding comes first because it is written
  # first: the row is created with it, and only a started workflow adds a token.
  def change
    create_table :cd_rollout_workflow_tokens do |t|
      t.bigint :organization_id, null: false
      t.bigint :rollout_id, null: false
      t.timestamps_with_timezone null: false
      t.jsonb :token_binding, null: false
      t.jsonb :token

      t.index :rollout_id, unique: true, name: ROLLOUT_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
    end
  end
end
