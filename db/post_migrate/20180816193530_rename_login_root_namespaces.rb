# frozen_string_literal: true
class RenameLoginRootNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  # We're taking over the /login namespace as part of a fix for the Jira integration
  def up
    disable_statement_timeout do
      rename_root_paths 'login'
    end
  end

  def down
    disable_statement_timeout do
      revert_renames
    end
  end
end
