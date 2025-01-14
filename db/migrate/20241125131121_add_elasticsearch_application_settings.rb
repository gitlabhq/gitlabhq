# frozen_string_literal: true

class AddElasticsearchApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  def up
    add_column :application_settings, :elasticsearch, :jsonb, default: {}, null: false, if_not_exists: true

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(elasticsearch) = 'object')",
      'check_application_settings_elasticsearch_is_hash'
    )
  end

  def down
    remove_column :application_settings, :elasticsearch, if_exists: true
  end
end
