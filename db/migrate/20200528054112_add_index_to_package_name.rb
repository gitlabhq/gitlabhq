# frozen_string_literal: true

class AddIndexToPackageName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'package_name_index'

  def up
    add_concurrent_index(:packages_packages, :name, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:packages_packages, :name, name: INDEX_NAME)
  end
end
