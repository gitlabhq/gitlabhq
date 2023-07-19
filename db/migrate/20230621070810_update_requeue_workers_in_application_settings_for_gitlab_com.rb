# frozen_string_literal: true

class UpdateRequeueWorkersInApplicationSettingsForGitlabCom < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com?

    execute 'UPDATE application_settings SET elasticsearch_requeue_workers = true'
  end

  def down
    return unless Gitlab.com?

    execute 'UPDATE application_settings SET elasticsearch_requeue_workers = false'
  end
end
