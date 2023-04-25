# frozen_string_literal: true

class CreateSecurityTrainingProviders < Gitlab::Database::Migration[1.0]
  def change
    create_table :security_training_providers do |t|
      t.text :name, limit: 256, null: false
      t.text :description, limit: 512
      t.text :url, limit: 512, null: false
      t.text :logo_url, limit: 512

      t.timestamps_with_timezone null: false
    end
  end
end
