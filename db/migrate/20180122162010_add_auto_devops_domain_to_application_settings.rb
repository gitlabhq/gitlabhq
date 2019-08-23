# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAutoDevopsDomainToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :application_settings, :auto_devops_domain, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
