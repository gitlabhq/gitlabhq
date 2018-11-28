class DeleteOrphanNotificationSettings < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    execute("DELETE FROM notification_settings WHERE EXISTS (SELECT true FROM (#{orphan_notification_settings}) AS ns WHERE ns.id = notification_settings.id)")
  end

  def down
    # This is a no-op method to make the migration reversible.
    # If someone is trying to rollback for other reasons, we should not throw an Exception.
    # raise ActiveRecord::IrreversibleMigration
  end

  def orphan_notification_settings
    <<-SQL
      SELECT notification_settings.id
      FROM   notification_settings
             LEFT OUTER JOIN namespaces
                          ON namespaces.id = notification_settings.source_id
      WHERE  notification_settings.source_type = 'Namespace'
             AND namespaces.id IS NULL
    SQL
  end
end
