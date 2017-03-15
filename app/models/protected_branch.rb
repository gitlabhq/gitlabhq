class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  has_many :merge_access_levels, dependent: :destroy
  has_many :push_access_levels, dependent: :destroy

  validates :merge_access_levels, length: { is: 1, message: "are restricted to a single instance per protected branch." }
  validates :push_access_levels, length: { is: 1, message: "are restricted to a single instance per protected branch." }

  accepts_nested_attributes_for :push_access_levels
  accepts_nested_attributes_for :merge_access_levels

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

  private

  def ref_matcher
    @ref_matcher ||= ProtectedRefMatcher.new(self)
  end
end
