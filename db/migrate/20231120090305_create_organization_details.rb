# frozen_string_literal: true

class CreateOrganizationDetails < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def change
    create_table :organization_details, id: false do |t|
      t.references :organization, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :cached_markdown_version
      t.text :description, limit: 1024
      t.text :description_html # rubocop:disable Migration/AddLimitToTextColumns -- It will be limited by description
    end
  end
end
