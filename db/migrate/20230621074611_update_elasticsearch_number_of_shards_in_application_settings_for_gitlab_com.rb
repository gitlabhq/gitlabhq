# frozen_string_literal: true

class UpdateElasticsearchNumberOfShardsInApplicationSettingsForGitlabCom < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  enable_lock_retries!

  def up
    return unless Gitlab.com?

    execute 'UPDATE application_settings SET elasticsearch_worker_number_of_shards = 16'
  end

  def down
    return unless Gitlab.com?

    execute 'UPDATE application_settings SET elasticsearch_worker_number_of_shards = 2'
  end
end
