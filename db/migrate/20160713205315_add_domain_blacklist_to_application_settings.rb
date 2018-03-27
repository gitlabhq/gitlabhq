# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable Migration/SaferBooleanColumn
class AddDomainBlacklistToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # When using the methods "add_concurrent_index" or "add_column_with_default"
  # you must disable the use of transactions as these methods can not run in an
  # existing transaction. When using "add_concurrent_index" make sure that this
  # method is the _only_ method called in the migration, any other changes
  # should go in a separate migration. This ensures that upon failure _only_ the
  # index creation fails and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

  def change
    add_column :application_settings, :domain_blacklist_enabled, :boolean, default: false
    add_column :application_settings, :domain_blacklist, :text
  end
end
