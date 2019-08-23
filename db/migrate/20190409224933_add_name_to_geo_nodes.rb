# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddNameToGeoNodes < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column :geo_nodes, :name, :string # rubocop:disable Migration/AddLimitToStringColumns

    # url is also unique, and its type and size is identical to the name column,
    # so this is safe.
    execute "UPDATE geo_nodes SET name = url;"

    # url is also `null: false`, so this is safe.
    change_column :geo_nodes, :name, :string, null: false
  end

  def down
    remove_column :geo_nodes, :name
  end
end
