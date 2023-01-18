# frozen_string_literal: true

module Projects
  class BranchRule
    extend Forwardable

    attr_reader :project, :protected_branch

    def_delegators(:protected_branch, :name, :group, :default_branch?, :created_at, :updated_at)

    def initialize(project, protected_branch)
      @protected_branch = protected_branch
      @project = project
    end

    def protected?
      true
    end

    def matching_branches_count
      branch_names = project.repository.branch_names
      matching_branches = protected_branch.matching(branch_names)
      matching_branches.count
    end

    def branch_protection
      protected_branch
    end
  end
end

Projects::BranchRule.prepend_mod
