# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameV2RootNamespaces < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  disable_ddl_transaction!

  # We're taking over the /v2 namespace as it necessary for Docker client to
  # work with GitLab as Dependency proxy for containers.
  def up
    disable_statement_timeout do
      rename_root_paths 'v2'
    end
  end

  def down
    disable_statement_timeout do
      revert_renames
    end
  end
end
