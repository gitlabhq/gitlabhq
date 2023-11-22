# frozen_string_literal: true

class AddObjectFormatToProjectRepositories < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  enable_lock_retries!

  def change
    add_column :project_repositories, :object_format, :smallint, null: false, default: 0
  end
end
