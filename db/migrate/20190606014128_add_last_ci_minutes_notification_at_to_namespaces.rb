# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLastCiMinutesNotificationAtToNamespaces < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :namespaces, :last_ci_minutes_notification_at, :datetime_with_timezone # rubocop:disable Migration/AddColumnsToWideTables
  end
end
