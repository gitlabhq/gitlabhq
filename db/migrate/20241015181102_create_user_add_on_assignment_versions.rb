# frozen_string_literal: true

class CreateUserAddOnAssignmentVersions < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    create_table :subscription_user_add_on_assignment_versions do |t| # rubocop:disable Migration/EnsureFactoryForTable -- No factory needed
      t.references :organization,
        foreign_key: true,
        null: false,
        index: { name: 'idx_user_add_on_assignment_versions_on_organization_id' }

      t.bigint :item_id
      t.bigint :purchase_id
      t.bigint :user_id
      t.datetime_with_timezone :created_at
      t.text   :item_type, null: false, limit: 255
      t.text   :event,     null: false, limit: 255
      t.text   :namespace_path, limit: 255
      t.text   :add_on_name, limit: 255
      t.text   :whodunnit, limit: 255
      t.jsonb  :object

      t.index :item_id, name: 'idx_user_add_on_assignment_versions_on_item_id'
    end
  end
end
