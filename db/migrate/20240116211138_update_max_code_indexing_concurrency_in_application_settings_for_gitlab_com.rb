# frozen_string_literal: true

class UpdateMaxCodeIndexingConcurrencyInApplicationSettingsForGitlabCom < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  enable_lock_retries!

  milestone '16.9'

  def up
    return unless Gitlab.com?

    execute 'UPDATE application_settings SET elasticsearch_max_code_indexing_concurrency = 60'
  end

  def down
    return unless Gitlab.com?

    execute 'UPDATE application_settings SET elasticsearch_max_code_indexing_concurrency = 30'
  end
end
