# frozen_string_literal: true

class AddClickHouseToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  def up
    add_column :application_settings, :clickhouse, :jsonb, default: {}, null: false

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(clickhouse) = 'object')",
      'check_application_settings_clickhouse_is_hash'
    )
  end

  def down
    remove_column :application_settings, :clickhouse
  end
end
