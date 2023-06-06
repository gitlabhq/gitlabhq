# frozen_string_literal: true

class RemoveProjectCiCdSettingOptInJwtColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column(:project_ci_cd_settings, :opt_in_jwt)
  end

  def down
    add_column(:project_ci_cd_settings, :opt_in_jwt, :boolean, default: false, null: false, if_not_exists: true)
  end
end
