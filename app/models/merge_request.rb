# == Schema Information
#
# Table name: merge_requests
#
#  id                :integer          not null, primary key
#  target_branch     :string(255)      not null
#  source_branch     :string(255)      not null
#  source_project_id :integer          not null
#  author_id         :integer
#  assignee_id       :integer
#  title             :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  st_commits        :text(2147483647)
#  st_diffs          :text(2147483647)
#  milestone_id      :integer
#  state             :string(255)
#  merge_status      :string(255)
#  target_project_id :integer          not null
#  iid               :integer
#  description       :text
#

require Rails.root.join("app/models/commit")
require Rails.root.join("lib/static_model")

class MergeRequest < ActiveRecord::Base
  include Issuable
  include InternalId

  belongs_to :target_project, foreign_key: :target_project_id, class_name: "Project"
  belongs_to :source_project, foreign_key: :source_project_id, class_name: "Project"

  attr_accessible :title, :assignee_id, :source_project_id, :source_branch, :target_project_id, :target_branch, :milestone_id, :author_id_of_changes, :state_event, :description

  attr_accessor :should_remove_source_branch

  # When this attribute is true some MR validation is ignored
  # It allows us to close or modify broken merge requests
  attr_accessor :allow_broken

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

  validates :source_project, presence: true, unless: :allow_broken
  validates :source_branch, presence: true
  validates :target_project, presence: true
  validates :target_branch, presence: true
  validate :validate_branches

  scope :of_group, ->(group) { where("source_project_id in (:group_project_ids) OR target_project_id in (:group_project_ids)", group_project_ids: group.project_ids) }
  scope :of_user_team, ->(team) { where("(source_project_id in (:team_project_ids) OR target_project_id in (:team_project_ids) AND assignee_id in (:team_member_ids))", team_project_ids: team.project_ids, team_member_ids: team.member_ids) }
  scope :opened, -> { with_state(:opened) }
  scope :closed, -> { with_state(:closed) }
  scope :merged, -> { with_state(:merged) }
  scope :by_branch, ->(branch_name) { where("(source_branch LIKE :branch) OR (target_branch LIKE :branch)", branch: branch_name) }
  scope :cared, ->(user) { where('assignee_id = :user OR author_id = :user', user: user.id) }
  scope :by_milestone, ->(milestone) { where(milestone_id: milestone) }
  scope :in_projects, ->(project_ids) { where("source_project_id in (:project_ids) OR target_project_id in (:project_ids)", project_ids: project_ids) }
  scope :of_projects, ->(ids) { where(target_project_id: ids) }
  # Closed scope for merge request should return
  # both merged and closed mr's
  scope :closed, -> { with_states(:closed, :merged) }

  def validate_branches
    if target_project==source_project && target_branch == source_branch
      errors.add :branch_conflict, "You can not use same project/branch for source and target"
    end

    if opened? || reopened?
      similar_mrs = self.target_project.merge_requests.where(source_branch: source_branch, target_branch: target_branch, source_project_id: source_project.id).opened
      similar_mrs = similar_mrs.where('id not in (?)', self.id) if self.id

      if similar_mrs.any?
        errors.add :base, "Cannot Create: This merge request already exists: #{similar_mrs.pluck(:title)}"
      end
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
    @diffs ||= (load_diffs(st_diffs) || [])
  end

  def reloaded_diffs
    if opened? && unmerged_diffs.any?
      self.st_diffs = dump_diffs(unmerged_diffs)
      self.save
    end
  end

  def broken_diffs?
    diffs == broken_diffs
  rescue
    true
  end

  def valid_diffs?
    !broken_diffs?
  end

  def unmerged_diffs
    diffs = if for_fork?
              Gitlab::Satellite::MergeAction.new(author, self).diffs_between_satellite
            else
              Gitlab::Git::Diff.between(target_project.repository, source_branch, target_branch)
            end

    diffs ||= []
    diffs
  end

  def last_commit
    commits.first
  end

  def merge_event
    self.target_project.events.where(target_id: self.id, target_type: "MergeRequest", action: Event::MERGED).last
  end

  def closed_event
    self.target_project.events.where(target_id: self.id, target_type: "MergeRequest", action: Event::CLOSED).last
  end

  def commits
    load_commits(st_commits || [])
  end

  def probably_merged?
    unmerged_commits.empty? &&
      commits.any? && opened?
  end

  def reloaded_commits
    if opened? && unmerged_commits.any?
      self.st_commits = dump_commits(unmerged_commits)
      save

    end
    commits
  end

  def unmerged_commits
    if for_fork?
      commits = Gitlab::Satellite::MergeAction.new(self.author, self).commits_between
    else
      commits = target_project.repository.commits_between(self.target_branch, self.source_branch)
    end

    if commits.present?
      commits = Commit.decorate(commits).
      sort_by(&:created_at).
      reverse
    end
    commits
  end

  def merge!(user_id)
    self.author_id_of_changes = user_id
    self.merge
  end

  def automerge!(current_user, commit_message = nil)
    if Gitlab::Satellite::MergeAction.new(current_user, self).merge!(commit_message) && self.unmerged_commits.empty?
      self.merge!(current_user.id)
      true
    end
  rescue
    mark_as_unmergeable
    false
  end

  def mr_and_commit_notes
    commit_ids = commits.map(&:id)
    project.notes.where(
      "(noteable_type = 'MergeRequest' AND noteable_id = :mr_id) OR (noteable_type = 'Commit' AND commit_id IN (:commit_ids))",
      mr_id: id,
      commit_ids: commit_ids
    )
  end

  # Returns the raw diff for this merge request
  #
  # see "git diff"
  def to_diff(current_user)
    Gitlab::Satellite::MergeAction.new(current_user, self).diff_in_satellite
  end

  # Returns the commit as a series of email patches.
  #
  # see "git format-patch"
  def to_patch(current_user)
    Gitlab::Satellite::MergeAction.new(current_user, self).format_patch
  end

  def last_commit_short_sha
    @last_commit_short_sha ||= last_commit.sha[0..10]
  end

  def for_fork?
    target_project != source_project
  end

  def disallow_source_branch_removal?
    (source_project.root_ref? source_branch) || for_fork?
  end

  def project
    target_project
  end

  # Return the set of issues that will be closed if this merge request is accepted.
  def closes_issues
    if target_branch == project.default_branch
      commits.map { |c| c.closes_issues(project) }.flatten.uniq.sort_by(&:id)
    else
      []
    end
  end

  # Mentionable override.
  def gfm_reference
    "merge request !#{iid}"
  end

  def target_project_path
    if target_project
      target_project.path_with_namespace
    else
      "(removed)"
    end
  end

  def source_project_path
    if source_project
      source_project.path_with_namespace
    else
      "(removed)"
    end
  end

  def source_branch_exists?
    return false unless self.source_project

    self.source_project.repository.branch_names.include?(self.source_branch)
  end

  def target_branch_exists?
    return false unless self.target_project

    self.target_project.repository.branch_names.include?(self.target_branch)
  end

  # Reset merge request events cache
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when a merge request is updated
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    Event.where(target_id: self.id, target_type: 'MergeRequest').
        order('id DESC').limit(100).
        update_all(updated_at: Time.now)
  end

  def merge_commit_message
    message = "Merge branch '#{source_branch}' into '#{target_branch}'"
    message << "\n\n"
    message << title.to_s
    message << "\n\n"
    message << description.to_s
    message
  end

  private

  def dump_commits(commits)
    commits.map(&:to_hash)
  end

  def load_commits(array)
    array.map { |hash| Commit.new(Gitlab::Git::Commit.new(hash)) }
  end

  def dump_diffs(diffs)
    if diffs == broken_diffs
      broken_diffs
    elsif diffs.respond_to?(:map)
      diffs.map(&:to_hash)
    end
  end

  def load_diffs(raw)
    if raw == broken_diffs
      broken_diffs
    elsif raw.respond_to?(:map)
      raw.map { |hash| Gitlab::Git::Diff.new(hash) }
    end
  end

  def broken_diffs
    [Gitlab::Git::Diff::BROKEN_DIFF]
  end
end
