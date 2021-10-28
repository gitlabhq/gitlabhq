# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddWarnAboutPotentiallyUnwantedCharactersToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :project_settings, :warn_about_potentially_unwanted_characters, :boolean, null: false, default: true
  end

  def down
    remove_column :project_settings, :warn_about_potentially_unwanted_characters
  end
end
