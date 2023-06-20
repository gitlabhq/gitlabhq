# frozen_string_literal: true

class AddVertexProjectToApplicationSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_column :application_settings, :vertex_project, :text, if_not_exists: true
    add_text_limit :application_settings, :vertex_project, 255
  end

  def down
    remove_text_limit :application_settings, :vertex_project
    remove_column :application_settings, :vertex_project, if_exists: true
  end
end
