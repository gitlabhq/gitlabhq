# frozen_string_literal: true

module Projects
  class AllBranchesRule < BranchRule
    include Projects::CustomBranchRule

    def name
      s_('All branches')
    end

    def matching_branches_count
      project.repository.branch_count
    end

    def squash_option
      project.project_setting
    end
  end
end
Projects::AllBranchesRule.prepend_mod_with('Projects::AllBranchesRule')
