# frozen_string_literal: true

class AddGroupCreationLevelToNamespaces < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!
  
  def up
    unless column_exists?(:namespaces, :subgroup_creation_level)
      add_column_with_default(:namespaces, :subgroup_creation_level, :integer, default: 0)
    end
  end

  def down
    if column_exists?(:namespaces, :subgroup_creation_level)
      remove_column(:namespaces, :subgroup_creation_level)
    end
  end
end
