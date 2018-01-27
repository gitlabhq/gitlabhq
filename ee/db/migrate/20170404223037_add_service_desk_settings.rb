# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddServiceDeskSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

  # When using the methods "add_concurrent_index" or "add_column_with_default"
  # you must disable the use of transactions as these methods can not run in an
  # existing transaction. When using "add_concurrent_index" make sure that this
  # method is the _only_ method called in the migration, any other changes
  # should go in a separate migration. This ensures that upon failure _only_ the
  # index creation fails and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  disable_ddl_transaction!

  def up
    add_column :users, :support_bot, :boolean

    add_column :projects, :service_desk_enabled, :boolean
    add_column :projects, :service_desk_mail_key, :string

    add_column :issues, :service_desk_reply_to, :string

    add_concurrent_index :users, :support_bot
    add_concurrent_index :projects, :service_desk_mail_key, unique: true
  end

  def down
    remove_column :users, :support_bot

    remove_column :projects, :service_desk_enabled
    remove_column :projects, :service_desk_mail_key

    remove_column :issues, :service_desk_reply_to
  end
end
