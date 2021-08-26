# frozen_string_literal: true

class CreateDependencyProxyImageTtlGroupPolicies < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      create_table :dependency_proxy_image_ttl_group_policies, id: false do |t|
        t.timestamps_with_timezone null: false
        t.references :group, primary_key: true, default: nil, index: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.integer :ttl, default: 90
        t.boolean :enabled, null: false, default: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :dependency_proxy_image_ttl_group_policies
    end
  end
end
