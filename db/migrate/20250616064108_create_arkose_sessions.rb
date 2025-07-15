# frozen_string_literal: true

class CreateArkoseSessions < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    create_table :arkose_sessions do |t|
      t.timestamptz :session_created_at, null: true
      t.timestamptz :checked_answer_at, null: true
      t.timestamptz :verified_at, null: false, index: true
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.integer :global_score, null: true
      t.integer :custom_score, null: true
      t.boolean :challenge_shown, null: false, default: false
      t.boolean :challenge_solved, null: false, default: false
      t.boolean :session_is_legit, null: false, default: true
      t.boolean :is_tor, null: false, default: false
      t.boolean :is_vpn, null: false, default: false
      t.boolean :is_proxy, null: false, default: false
      t.boolean :is_bot, null: false, default: false
      t.text :session_xid, limit: 64, null: false, index: true
      t.text :telltale_user, null: true, limit: 128
      t.text :user_agent, null: true, limit: 255
      t.text :user_language_shown, null: true, limit: 64
      t.text :device_xid, null: true, limit: 64
      t.text :telltale_list, null: false, array: true, default: []
      t.text :user_ip, null: true, limit: 64
      t.text :country, null: true, limit: 64
      t.text :region, null: true, limit: 64
      t.text :city, null: true, limit: 64
      t.text :isp, null: true, limit: 128
      t.text :connection_type, null: true, limit: 64
      t.text :risk_band, null: true, limit: 64
      t.text :risk_category, null: true, limit: 64
    end
  end
end
