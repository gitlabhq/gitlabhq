# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddServerlessFunctions < ActiveRecord::Migration
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
  # disable_ddl_transaction!

  def change
    create_table "serverless_functions" do |t|
      t.integer "project_id", null: false, index: true
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.string "name"
      t.string "runtime_image"
      t.text "function_code"
    end

    add_index :serverless_functions, [:project_id, :name], unique: true
  end
end
