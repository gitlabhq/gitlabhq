# frozen_string_literal: true

class RenameTofaSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :application_settings, :encrypted_tofa_credentials, :encrypted_vertex_ai_credentials
    rename_column_concurrently :application_settings, :encrypted_tofa_credentials_iv,
      :encrypted_vertex_ai_credentials_iv

    rename_column_concurrently :application_settings, :vertex_project, :vertex_ai_project
  end

  def down
    undo_rename_column_concurrently :application_settings, :encrypted_tofa_credentials, :encrypted_vertex_ai_credentials
    undo_rename_column_concurrently :application_settings, :encrypted_tofa_credentials_iv,
      :encrypted_vertex_ai_credentials_iv

    undo_rename_column_concurrently :application_settings, :vertex_project, :vertex_ai_project
  end
end
