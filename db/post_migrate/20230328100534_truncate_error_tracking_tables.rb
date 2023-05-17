# frozen_string_literal: true

class TruncateErrorTrackingTables < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # Only truncate tables on Gitlab.com environments.
    # TRUNCATE is a DDL statement (it drops the table and re-creates it), so we want to run the
    # migration in DDL mode, but we also don't want to execute it against all schemas because
    # it's considered a write operation. So, we'll manually check and skip the migration if
    # it's on not `:gitlab_main`.
    return unless Gitlab.com? && Gitlab::Database.gitlab_schemas_for_connection(connection).include?(:gitlab_main)

    execute('TRUNCATE table error_tracking_errors CASCADE')
  end

  def down
    # noop
  end
end
