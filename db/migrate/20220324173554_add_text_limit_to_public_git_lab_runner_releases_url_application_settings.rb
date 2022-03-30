# frozen_string_literal: true

class AddTextLimitToPublicGitLabRunnerReleasesUrlApplicationSettings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :public_runner_releases_url, 255
  end

  def down
    remove_text_limit :application_settings, :public_runner_releases_url
  end
end
