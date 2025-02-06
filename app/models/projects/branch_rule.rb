# frozen_string_literal: true

module Projects
  class BranchRule
    include GlobalID::Identification
    extend Forwardable

    attr_reader :project, :protected_branch
    alias_method :branch_protection, :protected_branch

    def_delegators(:protected_branch, :id, :name, :group, :default_branch?, :created_at, :updated_at, :persisted?)

    def self.find(id)
      protected_branch = ProtectedBranch.find(id)

      new(protected_branch.project, protected_branch)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Couldn't find Projects::BranchRule with 'id'=#{id}"
    end

    def initialize(project, protected_branch)
      @project = project
      @protected_branch = protected_branch
    end

    def protected?
      true
    end

    def matching_branches_count
      branch_names = project.repository.branch_names
      matching_branches = protected_branch.matching(branch_names)
      matching_branches.count
    end

    def squash_option
      nil
    end
  end
end

Projects::BranchRule.prepend_mod
