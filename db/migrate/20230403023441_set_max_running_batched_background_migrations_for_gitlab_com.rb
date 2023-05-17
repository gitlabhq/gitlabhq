# frozen_string_literal: true

class SetMaxRunningBatchedBackgroundMigrationsForGitlabCom < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com? && !Gitlab.jh?

    execute 'UPDATE application_settings SET database_max_running_batched_background_migrations = 4'
  end

  def down
    return unless Gitlab.com? && !Gitlab.jh?

    execute 'UPDATE application_settings SET database_max_running_batched_background_migrations = 2'
  end
end
