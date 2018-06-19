# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateAssigneeToSeparateTable < ActiveRecord::Migration
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

  def up
    drop_table(:issue_assignees) if table_exists?(:issue_assignees)

    if Gitlab::Database.mysql?
      execute <<-EOF
        CREATE TABLE issue_assignees AS
          SELECT assignee_id AS user_id, id AS issue_id FROM issues WHERE assignee_id IS NOT NULL
      EOF
    else
      ApplicationRecord.transaction do
        execute('LOCK TABLE issues IN EXCLUSIVE MODE')

        execute <<-EOF
          CREATE TABLE issue_assignees AS
            SELECT assignee_id AS user_id, id AS issue_id FROM issues WHERE assignee_id IS NOT NULL
        EOF

        execute <<-EOF
            CREATE OR REPLACE FUNCTION replicate_assignee_id()
            RETURNS trigger AS
            $BODY$
            BEGIN
              if OLD IS NOT NULL AND OLD.assignee_id IS NOT NULL THEN
                  DELETE FROM issue_assignees WHERE issue_id = OLD.id;
              END IF;

              if NEW.assignee_id IS NOT NULL THEN
                  INSERT INTO issue_assignees (user_id, issue_id) VALUES (NEW.assignee_id, NEW.id);
              END IF;

              RETURN NEW;
            END;
            $BODY$
            LANGUAGE 'plpgsql'
            VOLATILE;

            CREATE TRIGGER replicate_assignee_id
            BEFORE INSERT OR UPDATE OF assignee_id
            ON issues
            FOR EACH ROW EXECUTE PROCEDURE replicate_assignee_id();
        EOF
      end
    end
  end

  def down
    drop_table(:issue_assignees) if table_exists?(:issue_assignees)

    if Gitlab::Database.postgresql?
      execute <<-EOF
        DROP TRIGGER IF EXISTS replicate_assignee_id ON issues;
        DROP FUNCTION IF EXISTS replicate_assignee_id();
      EOF
    end
  end
end
