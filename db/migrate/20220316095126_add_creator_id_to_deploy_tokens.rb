# frozen_string_literal: true

class AddCreatorIdToDeployTokens < Gitlab::Database::Migration[1.0]
  def change
    add_column :deploy_tokens, :creator_id, :bigint
  end
end
