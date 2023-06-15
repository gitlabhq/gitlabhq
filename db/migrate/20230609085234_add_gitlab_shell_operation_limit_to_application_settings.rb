# frozen_string_literal: true

class AddGitlabShellOperationLimitToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :gitlab_shell_operation_limit, :integer, default: 600
  end
end
