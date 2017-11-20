# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexForPushrulesIsSample < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

  # When using the methods "add_concurrent_index", "remove_concurrent_index" or
  # "add_column_with_default" you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  disable_ddl_transaction!

  # Careful, on MySQL the where clause is ignored. We make the index
  # on the same column as the WHERE clause (is_sample) even though
  # this is generally a silly thing to do because that way on MySQL
  # the resulting index on is_sample will still fix the same
  # queries. It'll just waste space indexing all rows where is_sample
  # is false as well. In this case there's only a single row where
  # is_sample is true so having it be the index key is harmless.

  def up
    return if index_exists? :push_rules, :is_sample

    add_concurrent_index(:push_rules, :is_sample, where: "is_sample")
  end

  def down
    return unless index_exists? :push_rules, :is_sample

    remove_concurrent_index(:push_rules, :is_sample, where: "is_sample")
  end
end
