# frozen_string_literal: true

class IncreasePypiVersionSize < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :packages_pypi_metadata, :required_python, 255
  end

  def down
    remove_text_limit :packages_pypi_metadata, :required_python
  end
end
