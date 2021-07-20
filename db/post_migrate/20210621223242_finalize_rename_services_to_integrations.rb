# frozen_string_literal: true

class FinalizeRenameServicesToIntegrations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    finalize_table_rename(:services, :integrations)
  end

  def down
    undo_finalize_table_rename(:services, :integrations)
  end
end
