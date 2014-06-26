# == Schema Information
#
# Table name: merge_request_diffs
#
#  id               :integer          not null, primary key
#  state            :string(255)      default("collected"), not null
#  st_commits       :text
#  st_diffs         :text
#  merge_request_id :integer          not null
#  created_at       :datetime
#  updated_at       :datetime
#

require Rails.root.join("app/models/commit")

class MergeRequestDiff < ActiveRecord::Base
  # Prevent store of diff
  # if commits amount more then 200
  COMMITS_SAFE_SIZE = 200

  attr_reader :commits, :diffs

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

  def commits
    @commits ||= load_commits(st_commits || [])
  end

  def last_commit
    commits.first
  end

  def last_commit_short_sha
    @last_commit_short_sha ||= last_commit.sha[0..10]
  end

  private

  def dump_commits(commits)
    commits.map(&:to_hash)
  end

  def load_commits(array)
    array.map { |hash| Commit.new(Gitlab::Git::Commit.new(hash)) }
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
    commits = if merge_request.for_fork?
                compare_action.commits
              else
                repository.commits_between(target_branch, source_branch)
              end

    if commits.present?
      commits = Commit.decorate(commits).
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
        new_diffs = []
      end

      if new_diffs.sum { |diff| diff.diff.lines.count } > Commit::DIFF_HARD_LIMIT_LINES
        self.state = :overflow_diff_lines_limit
        new_diffs = []
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
    diffs = if merge_request.for_fork?
              compare_action.diffs
            else
              Gitlab::Git::Diff.between(repository, source_branch, target_branch)
            end

    diffs ||= []
    diffs
  rescue Gitlab::Git::Diff::TimeoutError => ex
    self.state = :timeout
    diffs = []
  end

  def repository
    merge_request.target_project.repository
  end

  private

  def compare_action
    Gitlab::Satellite::CompareAction.new(
      merge_request.author,
      merge_request.target_project,
      merge_request.target_branch,
      merge_request.source_project,
      merge_request.source_branch
    )
  end
end
