# frozen_string_literal: true

class AddProviderToAiSelfHostedModels < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :ai_self_hosted_models, :provider, :integer, limit: 2, default: 0, null: false
  end
end
