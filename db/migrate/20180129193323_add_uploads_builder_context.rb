# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddUploadsBuilderContext < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    add_column :uploads, :mount_point, :string
    add_column :uploads, :secret, :string
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
