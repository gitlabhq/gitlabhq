# frozen_string_literal: true

class CreateCiRunnerControllerRunnerLevelScopings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = :ci_runner_controller_runner_level_scopings
  OPTIONS = {
    if_not_exists: true,
    options: 'PARTITION BY LIST (runner_type)',
    primary_key: %w[id runner_type]
  }

  def change
    create_table TABLE_NAME, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.bigint :runner_controller_id, null: false
      t.bigint :runner_id, null: false
      t.integer :runner_type, null: false, limit: 2
      t.timestamps_with_timezone null: false

      t.index [:runner_controller_id, :runner_id, :runner_type], unique: true,
        name: 'index_ci_rcrl_scopings_on_controller_id_and_runner_id_and_type'
      t.index [:runner_id, :runner_type],
        name: 'index_ci_rcrl_scopings_on_runner_id_and_type'
    end
  end
end
