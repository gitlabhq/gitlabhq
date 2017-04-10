class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include ProtectedRef

  protected_ref_access_levels :merge, :push

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

  # Check if branch name is marked as protected in the system
  def self.protected?(project, ref_name)
    return true if project.empty_repo? && default_branch_protected?

    self.matching(ref_name, protected_refs: project.protected_branches).present?
  end

  def self.default_branch_protected?
    current_application_settings.default_branch_protection == Gitlab::Access::PROTECTION_FULL ||
      current_application_settings.default_branch_protection == Gitlab::Access::PROTECTION_DEV_CAN_MERGE
  end
end
