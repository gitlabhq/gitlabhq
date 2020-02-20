# frozen_string_literal: true

class CleanupRenamePagesDomainsDomainTypeToScope < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :pages_domains, :domain_type, :scope
  end

  def down
    undo_cleanup_concurrent_column_rename :pages_domains, :domain_type, :scope
  end
end
