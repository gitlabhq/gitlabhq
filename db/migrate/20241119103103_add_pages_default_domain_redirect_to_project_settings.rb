# frozen_string_literal: true

class AddPagesDefaultDomainRedirectToProjectSettings < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :project_settings, :pages_default_domain_redirect, :text, if_not_exists: true
    end

    add_text_limit :project_settings, :pages_default_domain_redirect, 255
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :pages_default_domain_redirect, if_exists: true
    end
  end
end
