# frozen_string_literal: true

class AddEnvironmentScopeToGroupVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX = 'index_ci_group_variables_on_group_id_and_key'
  NEW_INDEX = 'index_ci_group_variables_on_group_id_and_key_and_environment'

  disable_ddl_transaction!

  def up
    unless column_exists?(:ci_group_variables, :environment_scope)
      # rubocop:disable Migration/AddLimitToTextColumns
      # Added in 20210305013509_add_text_limit_to_group_ci_variables_environment_scope
      add_column :ci_group_variables, :environment_scope, :text, null: false, default: '*'
      # rubocop:enable Migration/AddLimitToTextColumns
    end

    add_concurrent_index :ci_group_variables, [:group_id, :key, :environment_scope], unique: true, name: NEW_INDEX
    remove_concurrent_index_by_name :ci_group_variables, OLD_INDEX
  end

  def down
    remove_duplicates!

    add_concurrent_index :ci_group_variables, [:group_id, :key], unique: true, name: OLD_INDEX
    remove_concurrent_index_by_name :ci_group_variables, NEW_INDEX

    remove_column :ci_group_variables, :environment_scope
  end

  private

  def remove_duplicates!
    execute <<-SQL
      DELETE FROM ci_group_variables
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM ci_group_variables
        GROUP BY group_id, key
      )
    SQL
  end
end
