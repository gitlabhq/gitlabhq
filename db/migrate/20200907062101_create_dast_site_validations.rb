# frozen_string_literal: true

class CreateDastSiteValidations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:dast_site_validations)
      with_lock_retries do
        create_table :dast_site_validations do |t|
          t.references :dast_site_token, foreign_key: { on_delete: :cascade }, null: false, index: true

          t.timestamps_with_timezone null: false
          t.datetime_with_timezone :validation_started_at
          t.datetime_with_timezone :validation_passed_at
          t.datetime_with_timezone :validation_failed_at
          t.datetime_with_timezone :validation_last_retried_at

          t.integer :validation_strategy, null: false, limit: 2

          t.text :url_base, null: false
          t.text :url_path, null: false
        end
      end
    end

    add_concurrent_index :dast_site_validations, :url_base
    add_text_limit :dast_site_validations, :url_base, 255
    add_text_limit :dast_site_validations, :url_path, 255
  end

  def down
    with_lock_retries do
      drop_table :dast_site_validations
    end
  end
end
