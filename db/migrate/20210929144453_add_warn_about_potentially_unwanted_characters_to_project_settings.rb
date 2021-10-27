# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddWarnAboutPotentiallyUnwantedCharactersToProjectSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_settings, :warn_about_potentially_unwanted_characters, :boolean, null: false, default: true
    end
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :warn_about_potentially_unwanted_characters
    end
  end
end
