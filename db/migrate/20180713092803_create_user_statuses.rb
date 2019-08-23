# frozen_string_literal: true

class CreateUserStatuses < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :user_statuses, id: false, primary_key: :user_id do |t|
      t.references :user,
                   foreign_key: { on_delete: :cascade },
                   null: false,
                   primary_key: true
      t.integer :cached_markdown_version, limit: 4
      t.string :emoji, null: false, default: 'speech_balloon'
      t.string :message, limit: 100
      t.string :message_html
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
