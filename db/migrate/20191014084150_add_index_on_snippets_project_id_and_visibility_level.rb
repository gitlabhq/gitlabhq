# frozen_string_literal: true

class AddIndexOnSnippetsProjectIdAndVisibilityLevel < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippets, [:project_id, :visibility_level]
  end

  def down
    remove_concurrent_index :snippets, [:project_id, :visibility_level]
  end
end
