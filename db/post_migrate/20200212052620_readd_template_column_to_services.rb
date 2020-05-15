# frozen_string_literal: true

class ReaddTemplateColumnToServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/UpdateLargeTable
  def up
    return if column_exists? :services, :template

    # The migration to drop the template column never actually shipped
    # to production, so we should be okay to re-add it without worrying
    # about doing a data migration.  If we needed to restore the value
    # of `template`, we would look for entries with `project_id IS NULL`.
    add_column_with_default :services, :template, :boolean, default: false, allow_null: true # rubocop:disable Migration/AddColumnWithDefault
  end
  # rubocop:enable Migration/UpdateLargeTable

  def down
    # NOP since the column is expected to exist
  end
end
