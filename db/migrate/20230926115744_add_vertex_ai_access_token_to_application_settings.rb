# frozen_string_literal: true

class AddVertexAiAccessTokenToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :encrypted_vertex_ai_access_token, :binary
    add_column :application_settings, :encrypted_vertex_ai_access_token_iv, :binary
  end
end
