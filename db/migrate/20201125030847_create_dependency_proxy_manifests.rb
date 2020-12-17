# frozen_string_literal: true

class CreateDependencyProxyManifests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :dependency_proxy_manifests, if_not_exists: true do |t|
        t.timestamps_with_timezone
        t.references :group, index: false, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }, type: :bigint
        t.bigint :size
        t.integer :file_store, limit: 2
        t.text :file_name, null: false
        t.text :file, null: false
        t.text :digest, null: false

        t.index [:group_id, :digest], name: 'index_dependency_proxy_manifests_on_group_id_and_digest'
      end
    end

    add_text_limit :dependency_proxy_manifests, :file_name, 255
    add_text_limit :dependency_proxy_manifests, :file, 255
    add_text_limit :dependency_proxy_manifests, :digest, 255
  end

  def down
    drop_table :dependency_proxy_manifests
  end
end
