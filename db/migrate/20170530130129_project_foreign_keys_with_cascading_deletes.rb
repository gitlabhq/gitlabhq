# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ProjectForeignKeysWithCascadingDeletes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  CONCURRENCY = 4

  disable_ddl_transaction!

  # The tables/columns for which to remove orphans and add foreign keys. Order
  # matters as some tables/columns should be processed before others.
  TABLES = [
    [:boards, :projects, :project_id],
    [:lists, :labels, :label_id],
    [:lists, :boards, :board_id],
    [:services, :projects, :project_id],
    [:forked_project_links, :projects, :forked_to_project_id],
    [:merge_requests, :projects, :target_project_id],
    [:labels, :projects, :project_id],
    [:issues, :projects, :project_id],
    [:events, :projects, :project_id],
    [:milestones, :projects, :project_id],
    [:notes, :projects, :project_id],
    [:snippets, :projects, :project_id],
    [:web_hooks, :projects, :project_id],
    [:protected_branch_merge_access_levels, :protected_branches, :protected_branch_id],
    [:protected_branch_push_access_levels, :protected_branches, :protected_branch_id],
    [:protected_branches, :projects, :project_id],
    [:protected_tags, :projects, :project_id],
    [:deploy_keys_projects, :projects, :project_id],
    [:users_star_projects, :projects, :project_id],
    [:releases, :projects, :project_id],
    [:project_group_links, :projects, :project_id],
    [:pages_domains, :projects, :project_id],
    [:todos, :projects, :project_id],
    [:project_import_data, :projects, :project_id],
    [:project_features, :projects, :project_id],
    [:ci_builds, :projects, :project_id],
    [:ci_pipelines, :projects, :project_id],
    [:ci_runner_projects, :projects, :project_id],
    [:ci_triggers, :projects, :project_id],
    [:environments, :projects, :project_id],
    [:deployments, :projects, :project_id]
  ]

  def up
    # These existing foreign keys don't have an "ON DELETE CASCADE" clause.
    remove_foreign_key_without_error(:boards, :project_id)
    remove_foreign_key_without_error(:lists, :label_id)
    remove_foreign_key_without_error(:lists, :board_id)
    remove_foreign_key_without_error(:protected_branch_merge_access_levels,
                                     :protected_branch_id)

    remove_foreign_key_without_error(:protected_branch_push_access_levels,
                                     :protected_branch_id)

    remove_orphaned_rows
    add_foreign_keys

    # These columns are not indexed yet, meaning a cascading delete would take
    # forever.
    add_index_if_not_exists(:project_group_links, :project_id)
    add_index_if_not_exists(:pages_domains, :project_id)
  end

  def down
    TABLES.each do |(source, _, column)|
      remove_foreign_key_without_error(source, column)
    end

    add_foreign_key_if_not_exists(:boards, :projects, column: :project_id)
    add_foreign_key_if_not_exists(:lists, :labels, column: :label_id)
    add_foreign_key_if_not_exists(:lists, :boards, column: :board_id)

    add_foreign_key_if_not_exists(:protected_branch_merge_access_levels,
                               :protected_branches,
                               column: :protected_branch_id)

    add_foreign_key_if_not_exists(:protected_branch_push_access_levels,
                               :protected_branches,
                               column: :protected_branch_id)

    remove_index_without_error(:project_group_links, :project_id)
    remove_index_without_error(:pages_domains, :project_id)
  end

  def add_foreign_keys
    TABLES.each do |(source, target, column)|
      add_foreign_key_if_not_exists(source, target, column: column)
    end
  end

  # Removes orphans from various tables concurrently.
  def remove_orphaned_rows
    Gitlab::Database.with_connection_pool(CONCURRENCY) do |pool|
      queues = queues_for_rows(TABLES)

      threads = queues.map do |queue|
        Thread.new do
          pool.with_connection do |connection|
            Thread.current[:foreign_key_connection] = connection

            # Disables statement timeouts for the current connection. This is
            # necessary as removing of orphaned data might otherwise exceed the
            # statement timeout.
            disable_statement_timeout

            remove_orphans(*queue.pop) until queue.empty?

            steal_from_queues(queues - [queue])
          end
        end
      end

      threads.each(&:join)
    end
  end

  def steal_from_queues(queues)
    loop do
      stolen = false

      queues.each do |queue|
        # Stealing is racy so it's possible a pop might be called on an
        # already-empty queue.
        begin
          remove_orphans(*queue.pop(true))
          stolen = true
        rescue ThreadError
        end
      end

      break unless stolen
    end
  end

  def remove_orphans(source, target, column)
    quoted_source = quote_table_name(source)
    quoted_target = quote_table_name(target)
    quoted_column = quote_column_name(column)

    execute <<-EOF.strip_heredoc
    DELETE FROM #{quoted_source}
    WHERE NOT EXISTS (
      SELECT true
      FROM #{quoted_target}
      WHERE #{quoted_target}.id = #{quoted_source}.#{quoted_column}
    )
    AND #{quoted_source}.#{quoted_column} IS NOT NULL
    EOF
  end

  def add_foreign_key_if_not_exists(source, target, column:)
    return if foreign_key_exists?(source, target, column: column)

    add_concurrent_foreign_key(source, target, column: column)
  end

  def add_index_if_not_exists(table, column)
    return if index_exists?(table, column)

    add_concurrent_index(table, column)
  end

  def remove_foreign_key_without_error(table, column)
    remove_foreign_key(table, column: column)
  rescue ArgumentError
  end

  def remove_index_without_error(table, column)
    remove_concurrent_index(table, column)
  rescue ArgumentError
  end

  def connection
    # Rails memoizes connection objects, but this causes them to be shared
    # amongst threads; we don't want that.
    Thread.current[:foreign_key_connection] || ActiveRecord::Base.connection
  end

  def queues_for_rows(rows)
    queues = Array.new(CONCURRENCY) { Queue.new }
    slice_size = rows.length / CONCURRENCY

    # Divide all the tuples as evenly as possible amongst the queues.
    rows.each_slice(slice_size).each_with_index do |slice, index|
      bucket = index % CONCURRENCY

      slice.each do |row|
        queues[bucket] << row
      end
    end

    queues
  end
end
