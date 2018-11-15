# frozen_string_literal: true

class AddArchiveBuildsDurationToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:application_settings, :archive_builds_in_seconds, :integer, allow_null: true)
  end
end
