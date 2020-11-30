# frozen_string_literal: true

class CreateBulkImportFailures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:bulk_import_failures)
        create_table :bulk_import_failures do |t|
          t.references :bulk_import_entity,
            null: false,
            index: true,
            foreign_key: { on_delete: :cascade }

          t.datetime_with_timezone :created_at, null: false
          t.text :pipeline_class, null: false
          t.text :exception_class, null: false
          t.text :exception_message, null: false
          t.text :correlation_id_value, index: true
        end
      end
    end

    add_text_limit :bulk_import_failures, :pipeline_class, 255
    add_text_limit :bulk_import_failures, :exception_class, 255
    add_text_limit :bulk_import_failures, :exception_message, 255
    add_text_limit :bulk_import_failures, :correlation_id_value, 255
  end

  def down
    with_lock_retries do
      drop_table :bulk_import_failures
    end
  end
end
