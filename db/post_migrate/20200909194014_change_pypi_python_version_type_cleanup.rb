# frozen_string_literal: true

class ChangePypiPythonVersionTypeCleanup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_type_change(:packages_pypi_metadata, :required_python)
  end

  def down
    execute('UPDATE packages_pypi_metadata SET required_python = substring(required_python from 1 for 50)')
    change_column_type_concurrently :packages_pypi_metadata, :required_python, 'varchar(50)', batch_column_name: :package_id
  end
end
