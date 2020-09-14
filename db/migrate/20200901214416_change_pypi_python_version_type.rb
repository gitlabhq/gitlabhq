# frozen_string_literal: true

class ChangePypiPythonVersionType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_column_type_concurrently :packages_pypi_metadata, :required_python, :text, batch_column_name: :package_id # rubocop:disable Migration/AddLimitToTextColumns
  end

  def down
    cleanup_concurrent_column_type_change(:packages_pypi_metadata, :required_python)
    change_column_null :packages_pypi_metadata, :required_python, false
  end
end
