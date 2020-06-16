# frozen_string_literal: true

class CreateProjectAccessTokens < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :project_access_tokens, primary_key: [:personal_access_token_id, :project_id] do |t|
      t.column :personal_access_token_id, :bigint, null: false
      t.column :project_id, :bigint, null: false
    end

    add_index :project_access_tokens, :project_id
  end
end
