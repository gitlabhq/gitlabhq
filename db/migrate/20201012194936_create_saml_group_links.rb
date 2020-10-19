# frozen_string_literal: true

class CreateSamlGroupLinks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :saml_group_links, if_not_exists: true do |t|
        t.integer :access_level, null: false, limit: 2
        t.references :group, index: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
        t.timestamps_with_timezone
        t.text :saml_group_name, null: false

        t.index [:group_id, :saml_group_name], unique: true
      end
    end

    add_text_limit :saml_group_links, :saml_group_name, 255
  end

  def down
    with_lock_retries do
      drop_table :saml_group_links
    end
  end
end
