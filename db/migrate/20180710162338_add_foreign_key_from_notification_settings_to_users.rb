class AddForeignKeyFromNotificationSettingsToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class NotificationSetting < ActiveRecord::Base
    self.table_name = 'notification_settings'

    include EachBatch
  end

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    NotificationSetting.each_batch(of: 1000) do |batch|
      batch.where('NOT EXISTS (?)', User.select(1).where('users.id = notification_settings.user_id'))
        .delete_all
    end

    add_concurrent_foreign_key(:notification_settings, :users, column: :user_id, on_delete: :cascade)
  end

  def down
    remove_foreign_key(:notification_settings, column: :user_id)
  end
end
