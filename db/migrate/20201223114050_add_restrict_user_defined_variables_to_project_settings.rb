# frozen_string_literal: true

class AddRestrictUserDefinedVariablesToProjectSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_ci_cd_settings, :restrict_user_defined_variables, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_ci_cd_settings, :restrict_user_defined_variables
    end
  end
end
