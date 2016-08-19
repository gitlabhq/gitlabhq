# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveRedundantIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    indexes = [
      [:ci_taggings, 'ci_taggings_idx'],
      [:audit_events, 'index_audit_events_on_author_id'],
      [:audit_events, 'index_audit_events_on_type'],
      [:ci_builds, 'index_ci_builds_on_erased_by_id'],
      [:ci_builds, 'index_ci_builds_on_project_id_and_commit_id'],
      [:ci_builds, 'index_ci_builds_on_type'],
      [:ci_commits, 'index_ci_commits_on_project_id'],
      [:ci_commits, 'index_ci_commits_on_project_id_and_committed_at'],
      [:ci_commits, 'index_ci_commits_on_project_id_and_committed_at_and_id'],
      [:ci_commits, 'index_ci_commits_on_project_id_and_sha'],
      [:ci_commits, 'index_ci_commits_on_sha'],
      [:ci_events, 'index_ci_events_on_created_at'],
      [:ci_events, 'index_ci_events_on_is_admin'],
      [:ci_events, 'index_ci_events_on_project_id'],
      [:ci_jobs, 'index_ci_jobs_on_deleted_at'],
      [:ci_jobs, 'index_ci_jobs_on_project_id'],
      [:ci_projects, 'index_ci_projects_on_gitlab_id'],
      [:ci_projects, 'index_ci_projects_on_shared_runners_enabled'],
      [:ci_services, 'index_ci_services_on_project_id'],
      [:ci_sessions, 'index_ci_sessions_on_session_id'],
      [:ci_sessions, 'index_ci_sessions_on_updated_at'],
      [:ci_tags, 'index_ci_tags_on_name'],
      [:ci_triggers, 'index_ci_triggers_on_deleted_at'],
      [:identities, 'index_identities_on_created_at_and_id'],
      [:issues, 'index_issues_on_title'],
      [:keys, 'index_keys_on_created_at_and_id'],
      [:members, 'index_members_on_created_at_and_id'],
      [:members, 'index_members_on_type'],
      [:milestones, 'index_milestones_on_created_at_and_id'],
      [:namespaces, 'index_namespaces_on_visibility_level'],
      [:projects, 'index_projects_on_builds_enabled_and_shared_runners_enabled'],
      [:services, 'index_services_on_category'],
      [:services, 'index_services_on_created_at_and_id'],
      [:services, 'index_services_on_default'],
      [:snippets, 'index_snippets_on_created_at'],
      [:snippets, 'index_snippets_on_created_at_and_id'],
      [:todos, 'index_todos_on_state'],
      [:web_hooks, 'index_web_hooks_on_created_at_and_id'],

      # These indexes _may_ be used but they can be replaced by other existing
      # indexes.

      # There's already a composite index on (project_id, iid) which means that
      # a separate index for _just_ project_id is not needed.
      [:issues, 'index_issues_on_project_id'],

      # These are all composite indexes for the columns (created_at, id). In all
      # these cases there's already a standalone index for "created_at" which
      # can be used instead.
      #
      # Because the "id" column of these composite indexes is never needed (due
      # to "id" already being indexed as its a primary key) these composite
      # indexes are useless.
      [:issues, 'index_issues_on_created_at_and_id'],
      [:merge_requests, 'index_merge_requests_on_created_at_and_id'],
      [:namespaces, 'index_namespaces_on_created_at_and_id'],
      [:notes, 'index_notes_on_created_at_and_id'],
      [:projects, 'index_projects_on_created_at_and_id'],
      [:users, 'index_users_on_created_at_and_id'],
    ]

    transaction do
      indexes.each do |(table, index)|
        remove_index(table, name: index) if index_exists_by_name?(table, index)
      end
    end

    add_concurrent_index(:users, :created_at)
    add_concurrent_index(:projects, :created_at)
    add_concurrent_index(:namespaces, :created_at)
  end

  def down
    # We're only restoring the composite indexes that could be replaced with
    # individual ones, just in case somebody would ever want to revert.
    transaction do
      remove_index(:users, :created_at)
      remove_index(:projects, :created_at)
      remove_index(:namespaces, :created_at)
    end

    [:issues, :merge_requests, :namespaces, :notes, :projects, :users].each do |table|
      add_concurrent_index(table, [:created_at, :id],
                           name: "index_#{table}_on_created_at_and_id")
    end
  end

  # Rails' index_exists? doesn't work when you only give it a table and index
  # name. As such we have to use some extra code to check if an index exists for
  # a given name.
  def index_exists_by_name?(table, index)
    indexes_for_table[table].include?(index)
  end

  def indexes_for_table
    @indexes_for_table ||= Hash.new do |hash, table_name|
      hash[table_name] = indexes(table_name).map(&:name)
    end
  end
end
