# frozen_string_literal: true

class AddVertexAiHostToApplicationSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :vertex_ai_host, :text, if_not_exists: true
    end

    add_text_limit :application_settings, :vertex_ai_host, 255
  end

  def down
    remove_text_limit :application_settings, :vertex_ai_host

    with_lock_retries do
      remove_column :application_settings, :vertex_ai_host, if_exists: true
    end
  end
end
