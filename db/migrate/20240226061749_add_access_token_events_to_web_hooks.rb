# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAccessTokenEventsToWebHooks < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  enable_lock_retries!

  def change
    add_column :web_hooks, :resource_access_token_events, :boolean, null: false, default: false
  end
end
