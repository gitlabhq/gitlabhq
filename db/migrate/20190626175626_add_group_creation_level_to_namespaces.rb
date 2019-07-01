# frozen_string_literal: true

class AddGroupCreationLevelToNamespaces < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column(:namespaces, :subgroup_creation_level, :integer)
    change_column_default(:namespaces,
                          :subgroup_creation_level,
                          ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
  end

  def down
    remove_column(:namespaces, :subgroup_creation_level)
  end
end
