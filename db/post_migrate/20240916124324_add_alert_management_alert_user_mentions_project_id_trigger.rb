# frozen_string_literal: true

class AddAlertManagementAlertUserMentionsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :alert_management_alert_user_mentions,
      sharding_key: :project_id,
      parent_table: :alert_management_alerts,
      parent_sharding_key: :project_id,
      foreign_key: :alert_management_alert_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :alert_management_alert_user_mentions,
      sharding_key: :project_id,
      parent_table: :alert_management_alerts,
      parent_sharding_key: :project_id,
      foreign_key: :alert_management_alert_id
    )
  end
end
