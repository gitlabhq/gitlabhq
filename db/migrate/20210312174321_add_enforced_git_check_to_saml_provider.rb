# frozen_string_literal: true

class AddEnforcedGitCheckToSamlProvider < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :saml_providers, :git_check_enforced, :boolean, default: false, null: false
  end

  def down
    remove_column :saml_providers, :git_check_enforced
  end
end
