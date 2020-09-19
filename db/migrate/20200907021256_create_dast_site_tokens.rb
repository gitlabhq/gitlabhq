# frozen_string_literal: true

class CreateDastSiteTokens < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:dast_site_tokens)
      with_lock_retries do
        create_table :dast_site_tokens do |t|
          t.references :project, foreign_key: { on_delete: :cascade }, null: false, index: true

          t.timestamps_with_timezone null: false
          t.datetime_with_timezone :expired_at

          t.text :token, null: false, unique: true
          t.text :url, null: false
        end
      end
    end

    add_text_limit :dast_site_tokens, :token, 255
    add_text_limit :dast_site_tokens, :url, 255
  end

  def down
    with_lock_retries do
      drop_table :dast_site_tokens
    end
  end
end
