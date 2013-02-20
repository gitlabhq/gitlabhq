# == Schema Information
#
# Table name: merge_requests
#
#  id            :integer          not null, primary key
#  target_branch :string(255)      not null
#  source_branch :string(255)      not null
#  project_id    :integer          not null
#  author_id     :integer
#  assignee_id   :integer
#  title         :string(255)
#  state         :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  st_commits    :text(2147483647)
#  st_diffs      :text(2147483647)
#  merge_status  :integer          default(1), not null
#
#  milestone_id  :integer

require Rails.root.join("app/models/commit")
require Rails.root.join("lib/static_model")

class MergeRequest < ActiveRecord::Base
  include Issuable

  attr_accessible :title, :assignee_id, :target_branch, :source_branch, :milestone_id,
                  :author_id_of_changes, :state_event

  attr_accessor :should_remove_source_branch

  state_machine :state, initial: :opened do
    event :close do
      transition [:reopened, :opened] => :closed
    end

    event :merge do
      transition [:reopened, :opened] => :merged
    end

    event :reopen do
      transition closed: :reopened
    end

    state :opened

    state :reopened

    state :closed

    state :merged
  end

  BROKEN_DIFF = "--broken-diff"

  state_machine :merge_status, initial: :unchecked do
    event :mark_as_unchecked do
      transition [:can_be_merged, :cannot_be_merged] => :unchecked
    end

    event :mark_as_mergeable do
      transition unchecked: :can_be_merged
    end

    event :mark_as_unmergeable do
      transition unchecked: :cannot_be_merged
    end

    state :unchecked 

    state :can_be_merged

    state :cannot_be_merged
  end

  serialize :st_commits
  serialize :st_diffs

  validates :source_branch, presence: true
  validates :target_branch, presence: true
  validate  :validate_branches

  scope :merged, -> { with_state(:merged) }
  scope :by_branch, ->(branch_name) { where("source_branch LIKE :branch OR target_branch LIKE :branch", branch: branch_name) }
  scope :cared, ->(user) { where('assignee_id = :user OR author_id = :user', user: user.id) }
  scope :by_milestone, ->(milestone) { where("milestone_id = :milestone_id", milestone_id: milestone) }

  # DEPRECATED: Please use human_merge_status_name instead
  def human_merge_status
    human_merge_status_name
  end

  def validate_branches
    if target_branch == source_branch
      errors.add :base, "You can not use same branch for source and target branches"
    end
  end

  def reload_code
    self.reloaded_commits
    self.reloaded_diffs
  end

  def check_if_can_be_merged
    if Gitlab::Satellite::MergeAction.new(self.author, self).can_be_merged?
      mark_as_mergeable
    else
      mark_as_unmergeable
    end
  end

  def diffs
    st_diffs || []
  end

  def reloaded_diffs
    if opened? && unmerged_diffs.any?
      self.st_diffs = unmerged_diffs
      self.save
    end

  rescue Grit::Git::GitTimeout
    self.st_diffs = [BROKEN_DIFF]
    self.save
  end

  def broken_diffs?
    diffs == [BROKEN_DIFF]
  end

  def valid_diffs?
    !broken_diffs?
  end

  def unmerged_diffs
    # Only show what is new in the source branch compared to the target branch, not the other way around.
    # The linex below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
    # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
    common_commit = project.repo.git.native(:merge_base, {}, [target_branch, source_branch]).strip
    diffs = project.repo.diff(common_commit, source_branch)
  end

  def last_commit
    commits.first
  end

  def merge_event
    self.project.events.where(target_id: self.id, target_type: "MergeRequest", action: Event::MERGED).last
  end

  def closed_event
    self.project.events.where(target_id: self.id, target_type: "MergeRequest", action: Event::CLOSED).last
  end

  def commits
    st_commits || []
  end

  def probably_merged?
    unmerged_commits.empty? &&
      commits.any? && opened?
  end

  def reloaded_commits
    if opened? && unmerged_commits.any?
      self.st_commits = unmerged_commits
      save
    end
    commits
  end

  def unmerged_commits
    self.project.repo.
      commits_between(self.target_branch, self.source_branch).
      map {|c| Commit.new(c)}.
      sort_by(&:created_at).
      reverse
  end

  def merge!(user_id)
    self.merge

    Event.create(
      project: self.project,
      action: Event::MERGED,
      target_id: self.id,
      target_type: "MergeRequest",
      author_id: user_id
    )
  end

  def automerge!(current_user)
    if Gitlab::Satellite::MergeAction.new(current_user, self).merge! && self.unmerged_commits.empty?
      self.merge!(current_user.id)
      true
    end
  rescue
    mark_as_unmergeable
    false
  end

  def mr_and_commit_notes
    commit_ids = commits.map(&:id)
    Note.where("(noteable_type = 'MergeRequest' AND noteable_id = :mr_id) OR (noteable_type = 'Commit' AND commit_id IN (:commit_ids))", mr_id: id, commit_ids: commit_ids)
  end

  # Returns the raw diff for this merge request
  #
  # see "git diff"
  def to_diff
    project.repo.git.native(:diff, {timeout: 30, raise: true}, "#{target_branch}...#{source_branch}")
  end

  # Returns the commit as a series of email patches.
  #
  # see "git format-patch"
  def to_patch
    project.repo.git.format_patch({timeout: 30, raise: true, stdout: true}, "#{target_branch}..#{source_branch}")
  end

  def last_commit_short_sha
    @last_commit_short_sha ||= last_commit.sha[0..10]
  end
end
