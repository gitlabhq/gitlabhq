class AddWhenAndYamlVariablesToCiBuilds < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :ci_builds, :when, :string
    add_column :ci_builds, :yaml_variables, :text
  end
end
