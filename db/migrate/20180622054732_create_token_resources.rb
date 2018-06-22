class CreateTokenResources < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :token_resources do |t|
      t.belongs_to :personal_access_token, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.belongs_to :project, null: false, foreign_key: { on_delete: :cascade }, index: true
    end
  end
end
