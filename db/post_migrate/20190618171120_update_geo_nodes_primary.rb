# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateGeoNodesPrimary < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default(:geo_nodes, :primary, false)
    change_column_null(:geo_nodes, :primary, false, false)
  end

  def down
    change_column_default(:geo_nodes, :primary, nil)
    change_column_null(:geo_nodes, :primary, true)
  end
end
