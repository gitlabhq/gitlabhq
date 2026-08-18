# frozen_string_literal: true

class RemoveOptionsAndYamlVariablesFromPCiBuilds < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    remove_column :p_ci_builds, :options, if_exists: true
    remove_column :p_ci_builds, :yaml_variables, if_exists: true
  end

  def down
    add_column :p_ci_builds, :options, :text, if_not_exists: true
    add_column :p_ci_builds, :yaml_variables, :text, if_not_exists: true
  end
end
