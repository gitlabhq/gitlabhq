# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSourcegraphConfigurationToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column(:application_settings, :sourcegraph_enabled, :boolean, default: false, null: false)
    add_column(:application_settings, :sourcegraph_url, :string, null: true, limit: 255)
  end

  def down
    remove_column(:application_settings, :sourcegraph_enabled)
    remove_column(:application_settings, :sourcegraph_url)
  end
end
