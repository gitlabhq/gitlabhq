# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddModsecurityModeToIngressApplication < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:clusters_applications_ingress, :modsecurity_mode, :smallint, default: 0, allow_null: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :clusters_applications_ingress, :modsecurity_mode
  end
end
