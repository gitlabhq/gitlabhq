require_relative '../migrate/20180223120443_create_user_interacted_projects_table.rb'
# rubocop:disable AddIndex
# rubocop:disable AddConcurrentForeignKey
class BuildUserInteractedProjectsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  UNIQUE_INDEX_NAME = 'index_user_interacted_projects_on_project_id_and_user_id'

  disable_ddl_transaction!

  def up
    if Gitlab::Database.postgresql?
      PostgresStrategy.new
    else
      MysqlStrategy.new
    end.up

    if index_exists_by_name?(:user_interacted_projects, CreateUserInteractedProjectsTable::INDEX_NAME)
      remove_concurrent_index_by_name :user_interacted_projects, CreateUserInteractedProjectsTable::INDEX_NAME
    end
  end

  def down
    execute "TRUNCATE user_interacted_projects"

    if foreign_key_exists?(:user_interacted_projects, :user_id)
      remove_foreign_key :user_interacted_projects, :users
    end

    if foreign_key_exists?(:user_interacted_projects, :project_id)
      remove_foreign_key :user_interacted_projects, :projects
    end

    if index_exists_by_name?(:user_interacted_projects, UNIQUE_INDEX_NAME)
      remove_concurrent_index_by_name :user_interacted_projects, UNIQUE_INDEX_NAME
    end

    unless index_exists_by_name?(:user_interacted_projects, CreateUserInteractedProjectsTable::INDEX_NAME)
      add_concurrent_index :user_interacted_projects, [:project_id, :user_id], name: CreateUserInteractedProjectsTable::INDEX_NAME
    end
  end

  private

  class PostgresStrategy < ActiveRecord::Migration
    include Gitlab::Database::MigrationHelpers

    BATCH_SIZE = 100_000
    SLEEP_TIME = 5

    def up
      with_index(:events, [:author_id, :project_id], name: 'events_user_interactions_temp', where: 'project_id IS NOT NULL') do
        insert_missing_records

        # Do this once without lock to speed up the second invocation
        remove_duplicates
        with_table_lock(:user_interacted_projects) do
          remove_duplicates
          create_unique_index
        end

        remove_without_project
        with_table_lock(:user_interacted_projects, :projects) do
          remove_without_project
          create_fk :user_interacted_projects, :projects, :project_id
        end

        remove_without_user
        with_table_lock(:user_interacted_projects, :users) do
          remove_without_user
          create_fk :user_interacted_projects, :users, :user_id
        end
      end

      execute "ANALYZE user_interacted_projects"
    end

    private
    def insert_missing_records
      iteration = 0
      records = 0
      begin
        Rails.logger.info "Building user_interacted_projects table, batch ##{iteration}"
        result = execute <<~SQL
            INSERT INTO user_interacted_projects (user_id, project_id)
            SELECT e.user_id, e.project_id
            FROM (SELECT DISTINCT author_id AS user_id, project_id FROM events WHERE project_id IS NOT NULL) AS e
            LEFT JOIN user_interacted_projects ucp USING (user_id, project_id)
            WHERE ucp.user_id IS NULL
            LIMIT #{BATCH_SIZE}
        SQL
        iteration += 1
        records += result.cmd_tuples
        Rails.logger.info "Building user_interacted_projects table, batch ##{iteration} complete, created #{records} overall"
        Kernel.sleep(SLEEP_TIME) if result.cmd_tuples > 0
      end while result.cmd_tuples > 0
    end

    def remove_duplicates
      execute <<~SQL
        WITH numbered AS (select ctid, ROW_NUMBER() OVER (PARTITION BY (user_id, project_id)) as row_number, user_id, project_id from user_interacted_projects)
        DELETE FROM user_interacted_projects WHERE ctid IN (SELECT ctid FROM numbered WHERE row_number > 1);
      SQL
    end

    def remove_without_project
      execute "DELETE FROM user_interacted_projects WHERE NOT EXISTS (SELECT 1 FROM projects WHERE id = user_interacted_projects.project_id)"
    end

    def remove_without_user
      execute "DELETE FROM user_interacted_projects WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = user_interacted_projects.user_id)"
    end

    def create_fk(table, target, column)
      return if foreign_key_exists?(table, column)

      add_foreign_key table, target, column: column, on_delete: :cascade
    end

    def create_unique_index
      return if index_exists_by_name?(:user_interacted_projects, UNIQUE_INDEX_NAME)

      add_index :user_interacted_projects, [:project_id, :user_id], unique: true, name: UNIQUE_INDEX_NAME
    end

    # Protect table against concurrent data changes while still allowing reads
    def with_table_lock(*tables)
      ActiveRecord::Base.connection.transaction do
        execute "LOCK TABLE #{tables.join(", ")} IN SHARE MODE"
        yield
      end
    end

    def with_index(*args)
      add_concurrent_index(*args) unless index_exists?(*args)
      yield
    ensure
      remove_concurrent_index(*args) if index_exists?(*args)
    end
  end

  class MysqlStrategy < ActiveRecord::Migration
    include Gitlab::Database::MigrationHelpers

    def up
      execute <<~SQL
        INSERT INTO user_interacted_projects (user_id, project_id)
        SELECT e.user_id, e.project_id
        FROM (SELECT DISTINCT author_id AS user_id, project_id FROM events WHERE project_id IS NOT NULL) AS e
        LEFT JOIN user_interacted_projects ucp USING (user_id, project_id)
        WHERE ucp.user_id IS NULL
      SQL

      unless index_exists?(:user_interacted_projects, [:project_id, :user_id])
        add_concurrent_index :user_interacted_projects, [:project_id, :user_id], unique: true, name: UNIQUE_INDEX_NAME
      end

      unless foreign_key_exists?(:user_interacted_projects, :user_id)
        add_concurrent_foreign_key :user_interacted_projects, :users, column: :user_id, on_delete: :cascade
      end

      unless foreign_key_exists?(:user_interacted_projects, :project_id)
        add_concurrent_foreign_key :user_interacted_projects, :projects, column: :project_id, on_delete: :cascade
      end
    end
  end
end
