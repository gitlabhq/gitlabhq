# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddStaticObjectsExternalStorageColumnsToApplicationSettings < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :application_settings, :static_objects_external_storage_url, :string, limit: 255
    add_column :application_settings, :static_objects_external_storage_auth_token, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings
end
