# frozen_string_literal: true

class AddPublicGitLabRunnerReleasesUrlToApplicationSettings < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220324173554_add_text_limit_to_public_git_lab_runner_releases_url_application_settings
  def change
    add_column :application_settings, :public_runner_releases_url, :text, null: false, default: 'https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab-runner/releases'
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
