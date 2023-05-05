# frozen_string_literal: true

class AddDefaultToRequiredPythonOnPackagesPypiMetadata < Gitlab::Database::Migration[1.0]
  def up
    change_column_default(:packages_pypi_metadata, :required_python, '')
  end

  def down
    change_column_default(:packages_pypi_metadata, :required_python, nil)
  end
end
