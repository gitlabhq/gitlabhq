# frozen_string_literal: true

class CleanupProjectSettingPagesDefaultDomainRedirectRename < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :project_settings, :pages_default_domain_redirect, :pages_primary_domain
  end

  def down
    undo_cleanup_concurrent_column_rename :project_settings, :pages_default_domain_redirect, :pages_primary_domain,
      batch_column_name: :project_id
  end
end
