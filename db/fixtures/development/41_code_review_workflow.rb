# frozen_string_literal: true

# Seeds code review tables that had neither a factory nor a fixture, so migrations touching them
# were never exercised by db:migrate:multi-version-upgrade.
#
# Uses `insert_all` so rows can carry nulls that model validations would reject - a later NOT NULL
# migration needs something to trip on. Sharding keys are populated with the values their sync
# triggers would derive, so the rows match what the application writes.
class Gitlab::Seeder::CodeReviewWorkflow
  attr_reader :merge_request, :user, :project

  def initialize
    @merge_request = MergeRequest.first
    @user = User.first
    @project = @merge_request&.target_project
  end

  def seed!
    return warn_missing_dependencies unless merge_request && user && project&.project_namespace_id

    seed_merge_request_user_mentions
    seed_commit_user_mentions
    seed_excluded_merge_requests
  end

  private

  def warn_missing_dependencies
    warn "\nSkipping code review workflow seeds: no merge request, user or project namespace available"
  end

  # Two variants so both a populated and an empty mention list exist.
  def seed_merge_request_user_mentions
    rows = [
      { merge_request_id: merge_request.id, project_id: project.id,
        note_id: merge_request.notes.order(:id).first&.id, mentioned_users_ids: [user.id],
        mentioned_projects_ids: [project.id], mentioned_groups_ids: nil },
      { merge_request_id: merge_request.id, project_id: project.id,
        note_id: nil, mentioned_users_ids: nil,
        mentioned_projects_ids: nil, mentioned_groups_ids: nil }
    ]

    MergeRequestUserMention.insert_all(rows)
    print '.'
  end

  # `index_commit_user_mentions_on_note_id` is unique and unconditional, so each row needs its own
  # note. `namespace_id` matches what the `sync_sharding_key_with_notes_table` trigger derives for
  # a note on this project.
  def seed_commit_user_mentions
    mention_notes = commit_mention_notes
    return if mention_notes.empty?

    rows = mention_notes.each_with_index.map do |mention_note, index|
      {
        commit_id: mention_note.commit_id,
        note_id: mention_note.id,
        namespace_id: project.project_namespace_id,
        mentioned_users_ids: index == 0 ? [user.id] : nil,
        mentioned_projects_ids: nil,
        mentioned_groups_ids: nil
      }
    end

    CommitUserMention.insert_all(rows)
    print '.'
  end

  # Notes on real commits, found or created keyed on the commit SHA so re-runs reuse the same
  # notes and stay idempotent.
  def commit_mention_notes
    commits = project.repository.commits(project.default_branch, limit: 2)

    commits.filter_map do |commit|
      project.notes.where(noteable_type: 'Commit', commit_id: commit.sha).order(:id).first ||
        create_commit_note(commit)
    end
  rescue StandardError => e
    warn "\nCould not load commits for commit notes: #{e.message}"
    []
  end

  def create_commit_note(commit)
    Note.create!(
      project: project,
      author: user,
      noteable_type: 'Commit',
      commit_id: commit.sha,
      note: "Seeded note on commit #{commit.short_id}"
    )
  rescue StandardError => e
    warn "\nCould not create a commit note: #{e.message}"
    nil
  end

  # No model for this table. No unique constraint either, so guard to stay idempotent.
  def seed_excluded_merge_requests
    ApplicationRecord.connection.execute(<<~SQL.squish)
      INSERT INTO excluded_merge_requests (merge_request_id)
      SELECT #{merge_request.id.to_i}
      WHERE NOT EXISTS (
        SELECT 1 FROM excluded_merge_requests WHERE merge_request_id = #{merge_request.id.to_i}
      )
    SQL
    print '.'
  end
end

Gitlab::Seeder.quiet do
  puts "\nGenerating code review workflow data"

  Gitlab::Seeder::CodeReviewWorkflow.new.seed!
rescue StandardError => e
  warn "\nError seeding code review workflow data: #{e}"
end
