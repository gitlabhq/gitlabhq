# frozen_string_literal: true

module Projects
  # Service class that can be used to execute actions necessary after creating a
  # default branch.
  class ProtectDefaultBranchService
    attr_reader :project, :default_branch_protection

    # @param [Project] project
    def initialize(project)
      @project = project

      @default_branch_protection = Gitlab::Access::BranchProtection
        .new(project.namespace.default_branch_protection)
    end

    def execute
      protect_default_branch if default_branch
    end

    def protect_default_branch
      # Ensure HEAD points to the default branch in case it is not master
      project.change_head(default_branch)

      create_protected_branch if protect_branch? && !protected_branch_exists?
    end

    def create_protected_branch
      params = {
        name: default_branch,
        push_access_levels_attributes: [{ access_level: push_access_level }],
        merge_access_levels_attributes: [{ access_level: merge_access_level }]
      }

      # The creator of the project is always allowed to create protected
      # branches, so we skip the authorization check in this service class.
      ProtectedBranches::CreateService
        .new(project, project.creator, params)
        .execute(skip_authorization: true)
    end

    def protect_branch?
      default_branch_protection.any? &&
        !ProtectedBranch.protected?(project, default_branch)
    end

    def protected_branch_exists?
      project.protected_branches.find_by_name(default_branch).present?
    end

    def default_branch
      project.default_branch
    end

    def push_access_level
      if default_branch_protection.developer_can_push?
        Gitlab::Access::DEVELOPER
      else
        Gitlab::Access::MAINTAINER
      end
    end

    def merge_access_level
      if default_branch_protection.developer_can_merge?
        Gitlab::Access::DEVELOPER
      else
        Gitlab::Access::MAINTAINER
      end
    end
  end
end
