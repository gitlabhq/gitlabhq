# frozen_string_literal: true

class AddGitlabDedicatedInstanceToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :gitlab_dedicated_instance, :boolean, default: false, null: false
  end
end
