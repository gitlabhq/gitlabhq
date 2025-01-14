# frozen_string_literal: true

class RenamePagesDefaultDomainRedirectToPagesPrimaryDomain < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_999e5f0aaa'

  def up
    remove_check_constraint :project_settings, CONSTRAINT_NAME
    rename_column_concurrently :project_settings, :pages_default_domain_redirect, :pages_primary_domain,
      batch_column_name: :project_id
    add_text_limit :project_settings, :pages_primary_domain, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :project_settings, CONSTRAINT_NAME
    undo_rename_column_concurrently :project_settings, :pages_default_domain_redirect, :pages_primary_domain
    add_text_limit :project_settings, :pages_default_domain_redirect, 255, constraint_name: CONSTRAINT_NAME
  end
end
