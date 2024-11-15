# frozen_string_literal: true

class CreateCiRunnerTaggings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  TABLE_NAME = :ci_runner_taggings
  OPTIONS = {
    if_not_exists: true,
    options: 'PARTITION BY LIST (runner_type)',
    primary_key: %w[id runner_type]
  }

  def change
    create_table(TABLE_NAME, **OPTIONS) do |t|
      t.bigserial :id, null: false
      t.bigint :tag_id, null: false
      t.bigint :runner_id, null: false
      t.bigint :sharding_key_id, null: true
      t.integer :runner_type, null: false, limit: 2

      t.index [:tag_id, :runner_id, :runner_type], unique: true,
        name: 'index_ci_runner_taggings_on_tag_id_runner_id_and_runner_type'
      t.index [:runner_id, :runner_type]
      t.index [:sharding_key_id]
    end
  end
end
