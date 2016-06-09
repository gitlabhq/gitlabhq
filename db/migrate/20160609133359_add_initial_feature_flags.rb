# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddInitialFeatureFlags < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    columns = [
      :enable_toggling_award_emoji,
      :enable_creating_notes,
      :enable_updating_notes,
      :enable_removing_notes,
      :enable_removing_note_attachments
    ]

    columns.each do |column|
      add_column :application_settings, column, :boolean, default: true
    end
  end
end
