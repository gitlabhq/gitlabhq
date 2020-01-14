# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForcePagesAccessControlToApplicationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :application_settings, :force_pages_access_control, :boolean, null: false, default: false
  end
end
