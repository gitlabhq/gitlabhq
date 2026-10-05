# frozen_string_literal: true

class CreateTrialUsages < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.5'

  disable_ddl_transaction!

  TABLE_NAME = :trial_usages
  UNIQUE_INDEX_NAME = 'index_trial_usages_on_namespace_id_and_trial_ends_on'
  OPTIONS = {
    primary_key: [:id, :trial_ends_on],
    options: 'PARTITION BY RANGE (trial_ends_on)',
    if_not_exists: true
  }.freeze

  def up
    create_table TABLE_NAME, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.date :trial_starts_on, null: false
      t.date :trial_ends_on, null: false
      t.date :compute_minutes_month, null: false
      t.integer :max_seats_used, null: false, default: 0
      t.integer :compute_minutes_used, null: false, default: 0
      t.decimal :credits_used, precision: 14, scale: 4
      t.text :trial_type, limit: 255

      t.check_constraint 'max_seats_used >= 0', name: 'check_trial_usages_max_seats_used_non_negative'
      t.check_constraint 'compute_minutes_used >= 0', name: 'check_trial_usages_compute_minutes_used_non_negative'
      t.check_constraint 'credits_used >= 0', name: 'check_trial_usages_credits_used_non_negative'
      t.check_constraint 'trial_ends_on > trial_starts_on', name: 'check_trial_usages_trial_ends_on_after_starts_on'

      t.index [:namespace_id, :trial_ends_on], unique: true, name: UNIQUE_INDEX_NAME
    end

    add_concurrent_partitioned_foreign_key TABLE_NAME, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    drop_table TABLE_NAME
  end
end
