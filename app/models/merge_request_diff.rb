# == Schema Information
#
# Table name: merge_request_diffs
#
#  id               :integer          not null, primary key
#  state            :string(255)
#  st_commits       :text
#  st_diffs         :text
#  merge_request_id :integer          not null
#  created_at       :datetime
#  updated_at       :datetime
#

require Rails.root.join("app/models/commit")

class MergeRequestDiff < ActiveRecord::Base
  include Sortable

  # Prevent store of diff if commits amount more then 500
  COMMITS_SAFE_SIZE = 500

  attr_reader :commits, :diffs, :diffs_no_whitespace

  belongs_to :merge_request

  delegate :target_branch, :source_branch, to: :merge_request, prefix: nil

  state_machine :state, initial: :empty do
    state :collected
    state :timeout
    state :overflow_commits_safe_size
    state :overflow_diff_files_limit
    state :overflow_diff_lines_limit
  end

  serialize :st_commits
  serialize :st_diffs

  after_create :reload_content

  def reload_content
    reload_commits
    reload_diffs
  end

  def diffs
    @diffs ||= (load_diffs(st_diffs) || [])
  end

  def diffs_no_whitespace
    # Get latest sha of branch from source project
    source_sha = merge_request.source_project.commit(source_branch).sha

    compare_result = Gitlab::CompareResult.new(
      Gitlab::Git::Compare.new(
        merge_request.target_project.repository.raw_repository,
        merge_request.target_branch,
        source_sha,
      ), { ignore_whitespace_change: true }
    )
    @diffs_no_whitespace ||= load_diffs(dump_commits(compare_result.diffs))
  end

  def commits
    @commits ||= load_commits(st_commits || [])
  end

  def last_commit
    commits.first
  end

  def first_commit
    commits.last
  end

  def last_commit_short_sha
    @last_commit_short_sha ||= last_commit.short_id
  end

  private

  def dump_commits(commits)
    commits.map(&:to_hash)
  end

  def load_commits(array)
    array.map { |hash| Commit.new(Gitlab::Git::Commit.new(hash), merge_request.source_project) }
  end

  def dump_diffs(diffs)
    if diffs.respond_to?(:map)
      diffs.map(&:to_hash)
    end
  end

  def load_diffs(raw)
    if raw.respond_to?(:map)
      raw.map { |hash| Gitlab::Git::Diff.new(hash) }
    end
  end

  # Collect array of Git::Commit objects
  # between target and source branches
  def unmerged_commits
    commits = compare_result.commits

    if commits.present?
      commits = Commit.decorate(commits, merge_request.source_project).
        sort_by(&:created_at).
        reverse
    end

    commits
  end

  # Reload all commits related to current merge request from repo
  # and save it as array of hashes in st_commits db field
  def reload_commits
    commit_objects = unmerged_commits

    if commit_objects.present?
      self.st_commits = dump_commits(commit_objects)
    end

    save
  end

  # Reload diffs between branches related to current merge request from repo
  # and save it as array of hashes in st_diffs db field
  def reload_diffs
    new_diffs = []

    if commits.size.zero?
      self.state = :empty
    elsif commits.size > COMMITS_SAFE_SIZE
      self.state = :overflow_commits_safe_size
    else
      new_diffs = unmerged_diffs
    end

    if new_diffs.any?
      if new_diffs.size > Commit::DIFF_HARD_LIMIT_FILES
        self.state = :overflow_diff_files_limit
        new_diffs = new_diffs.first(Commit::DIFF_HARD_LIMIT_LINES)
      end

      if new_diffs.sum { |diff| diff.diff.lines.count } > Commit::DIFF_HARD_LIMIT_LINES
        self.state = :overflow_diff_lines_limit
        new_diffs = new_diffs.first(Commit::DIFF_HARD_LIMIT_LINES)
      end
    end

    if new_diffs.present?
      new_diffs = dump_commits(new_diffs)
      self.state = :collected
    end

    self.st_diffs = new_diffs
    self.save
  end

  # Collect array of Git::Diff objects
  # between target and source branches
  def unmerged_diffs
    compare_result.diffs || []
  rescue Gitlab::Git::Diff::TimeoutError
    self.state = :timeout
    []
  end

  def repository
    merge_request.target_project.repository
  end

  private

  def compare_result
    @compare_result ||=
      begin
        # Update ref for merge request
        merge_request.fetch_ref

        # Get latest sha of branch from source project
        source_commit = merge_request.source_project.commit(source_branch)
        source_sha = source_commit.try(:sha)

        Gitlab::CompareResult.new(
          Gitlab::Git::Compare.new(
            merge_request.target_project.repository.raw_repository,
            merge_request.target_branch,
            source_sha,
          )
        )
      end
  end
end
