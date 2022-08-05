# frozen_string_literal: true

class CreateNamespaceDetails < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :namespace_details, id: false do |t|
        t.references :namespace, primary_key: true, null: false, default: nil, type: :bigint, index: false, foreign_key: { on_delete: :cascade } # rubocop:disable Layout/LineLength
        t.timestamps_with_timezone null: true
        t.integer :cached_markdown_version
        t.text :description, limit: 255
        t.text :description_html, limit: 255
      end
    end
  end

  def down
    drop_table :namespace_details
  end
end
