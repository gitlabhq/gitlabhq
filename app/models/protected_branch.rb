class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  has_many :merge_access_levels, dependent: :destroy
  has_many :push_access_levels, dependent: :destroy

  validates :merge_access_levels, length: { minimum: 0 }
  validates :push_access_levels, length: { minimum: 0 }

  accepts_nested_attributes_for :push_access_levels, allow_destroy: true
  accepts_nested_attributes_for :merge_access_levels, allow_destroy: true

  # Returns all merge access levels (for protected branches in scope) that grant merge
  # access to the given user.
  scope :merge_access_by_user, -> (user) { MergeAccessLevel.joins(:protected_branch).where(protected_branch_id: self.ids).merge(MergeAccessLevel.by_user(user)) }

  # Returns all push access levels (for protected branches in scope) that grant push
  # access to the given user.
  scope :push_access_by_user, -> (user) { PushAccessLevel.joins(:protected_branch).where(protected_branch_id: self.ids).merge(PushAccessLevel.by_user(user)) }

  # Returns all merge access levels (for protected branches in scope) that grant merge
  # access to the given group.
  scope :merge_access_by_group, -> (group) { MergeAccessLevel.joins(:protected_branch).where(protected_branch_id: self.ids).merge(MergeAccessLevel.by_group(group)) }

  # Returns all push access levels (for protected branches in scope) that grant push
  # access to the given group.
  scope :push_access_by_group, -> (group) { PushAccessLevel.joins(:protected_branch).where(protected_branch_id: self.ids).merge(PushAccessLevel.by_group(group)) }

  def commit
    project.commit(self.name)
  end

  def self.matching(branch_name, protected_branches: nil)
    ProtectedRefMatcher.matching(ProtectedBranch, branch_name, protected_refs: protected_branches)
  end

  def matching(branches)
    ref_matcher.matching(branches)
  end

  def matches?(branch_name)
    ref_matcher.matches?(branch_name)
  end

  def wildcard?
    ref_matcher.wildcard?
  end

  # Returns a hash were keys are types of push access levels (user, role), and
  # values are the number of access levels of the particular type.
  def push_access_level_frequencies
    push_access_levels.reduce(Hash.new(0)) do |frequencies, access_level|
      frequencies[access_level.type] = frequencies[access_level.type] + 1
      frequencies
    end
  end

  # Returns a hash were keys are types of merge access levels (user, role), and
  # values are the number of access levels of the particular type.
  def merge_access_level_frequencies
    merge_access_levels.reduce(Hash.new(0)) do |frequencies, access_level|
      frequencies[access_level.type] = frequencies[access_level.type] + 1
      frequencies
    end
  end

  private

  def ref_matcher
    @ref_matcher ||= ProtectedRefMatcher.new(self)
  end
end
