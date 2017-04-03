class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include ProtectedRef

  has_many :merge_access_levels, dependent: :destroy
  has_many :push_access_levels, dependent: :destroy

  validates :merge_access_levels, length: { is: 1, message: "are restricted to a single instance per protected branch." }
  validates :push_access_levels, length: { is: 1, message: "are restricted to a single instance per protected branch." }

  accepts_nested_attributes_for :push_access_levels
  accepts_nested_attributes_for :merge_access_levels

  # Check if branch name is marked as protected in the system
  def self.protected?(project, ref_name)
    return true if project.empty_and_default_branch_protected?

    protected_refs = project.protected_branches_array
    self.matching(ref_name, protected_refs: protected_refs).present?
  end
end
