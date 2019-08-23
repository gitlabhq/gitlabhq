# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# We are reverting the feature that created this column. This is for anyone who
# migrated while the feature still existed in master.
class RemoveAlternateUrlFromGeoNodes < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    remove_column(:geo_nodes, :alternate_url) if column_exists?(:geo_nodes, :alternate_url)
  end

  def down
    add_column :geo_nodes, :alternate_url, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
