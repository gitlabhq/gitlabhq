# frozen_string_literal: true

class AddToggleOptInJwt < Gitlab::Database::Migration[2.0]
  def change
    add_column :project_ci_cd_settings, :opt_in_jwt, :boolean, default: false, null: false
  end
end
