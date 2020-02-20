# frozen_string_literal: true

class RenamePagesDomainsDomainTypeToScope < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :pages_domains, :domain_type, :scope
  end

  def down
    undo_rename_column_concurrently :pages_domains, :domain_type, :scope
  end
end
