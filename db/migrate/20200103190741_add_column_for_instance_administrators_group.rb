# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddColumnForInstanceAdministratorsGroup < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :application_settings, :instance_administrators_group_id, :integer
  end
end
