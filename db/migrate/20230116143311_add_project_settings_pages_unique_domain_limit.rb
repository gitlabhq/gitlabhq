# frozen_string_literal: true

class AddProjectSettingsPagesUniqueDomainLimit < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :pages_unique_domain, 63
  end

  def down
    remove_text_limit :project_settings, :pages_unique_domain
  end
end
