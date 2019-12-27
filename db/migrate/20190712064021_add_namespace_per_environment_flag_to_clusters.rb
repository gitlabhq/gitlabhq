# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddNamespacePerEnvironmentFlagToClusters < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :clusters, :namespace_per_environment, :boolean, default: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :clusters, :namespace_per_environment
  end
end
