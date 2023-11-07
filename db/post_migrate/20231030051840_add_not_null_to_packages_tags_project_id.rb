# frozen_string_literal: true

class AddNotNullToPackagesTagsProjectId < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :packages_tags, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :packages_tags, :project_id
  end
end
