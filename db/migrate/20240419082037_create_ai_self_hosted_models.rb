# frozen_string_literal: true

class CreateAiSelfHostedModels < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    create_table :ai_self_hosted_models do |t|
      t.timestamps_with_timezone null: false
      t.integer :model, limit: 2, null: false
      t.text :endpoint, limit: 2048, null: false
      t.text :name, limit: 255, null: false, index: { unique: true }
      t.binary :encrypted_api_token
      t.binary :encrypted_api_token_iv
    end
  end
end
