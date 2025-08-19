# frozen_string_literal: true

class DropRestrictUserDefinedVariables < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    remove_column :project_ci_cd_settings, :restrict_user_defined_variables
  end

  def down
    add_column :project_ci_cd_settings, :restrict_user_defined_variables, :boolean, default: false, null: false
  end
end
