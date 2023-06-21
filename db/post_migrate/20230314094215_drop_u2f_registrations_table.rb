# frozen_string_literal: true

class DropU2fRegistrationsTable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    drop_table :u2f_registrations
  end

  def down
    create_table :u2f_registrations do |t| # rubocop: disable Migration/SchemaAdditionMethodsNoPost
      t.text :certificate
      t.string :key_handle
      t.string :public_key
      t.integer :counter
      t.references :user, foreign_key: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.string :name
      t.index [:key_handle], name: 'index_u2f_registrations_on_key_handle'
    end
  end
end
