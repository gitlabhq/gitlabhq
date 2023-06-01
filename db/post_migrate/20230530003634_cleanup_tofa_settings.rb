# frozen_string_literal: true

class CleanupTofaSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings, :encrypted_tofa_credentials,
      :encrypted_vertex_ai_credentials
    cleanup_concurrent_column_rename :application_settings, :encrypted_tofa_credentials_iv,
      :encrypted_vertex_ai_credentials_iv
    cleanup_concurrent_column_rename :application_settings, :vertex_project,
      :vertex_ai_project
  end

  def down
    undo_cleanup_concurrent_column_rename :application_settings, :encrypted_tofa_credentials,
      :encrypted_vertex_ai_credentials
    undo_cleanup_concurrent_column_rename :application_settings, :encrypted_tofa_credentials_iv,
      :encrypted_vertex_ai_credentials_iv
    undo_cleanup_concurrent_column_rename :application_settings, :vertex_project,
      :vertex_ai_project
  end
end
