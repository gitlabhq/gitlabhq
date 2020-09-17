# frozen_string_literal: true

class CreatePagesDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :pages_deployments, if_not_exists: true do |t|
      t.timestamps_with_timezone

      t.bigint :project_id, index: true, null: false
      t.bigint :ci_build_id, index: true

      t.integer :file_store, null: false, limit: 2
      t.integer :size, null: false
      t.text :file, null: false
    end

    add_text_limit :pages_deployments, :file, 255
  end

  def down
    drop_table :pages_deployments
  end
end
