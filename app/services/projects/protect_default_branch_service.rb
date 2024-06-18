# frozen_string_literal: true

module Projects
  # Service class that can be used to execute actions necessary after creating a
  # default branch.
  class ProtectDefaultBranchService
    attr_reader :project, :default_branch_protection

    # @param [Project] project
    def initialize(project)
      @project = project

      @default_branch_protection = Gitlab::Access::DefaultBranchProtection.new(
        project.namespace.default_branch_protection_settings
      )
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
        merge_access_levels_attributes: [{ access_level: merge_access_level }],
        code_owner_approval_required: code_owner_approval_required?,
        allow_force_push: allow_force_push?
      }

      # The creator of the project is always allowed to create protected
      # branches, so we skip the authorization check in this service class.
      ProtectedBranches::CreateService
        .new(project, project.creator, params)
        .execute(skip_authorization: true)
    end

    # overriden in EE
    def code_owner_approval_required?
      false
    end

    def allow_force_push?
      default_branch_protection.allow_force_push?
    end

    def protect_branch?
      default_branch_protection.any? &&
        !ProtectedBranch.protected?(project, default_branch)
    end

    def protected_branch_exists?
      project.all_protected_branches.find_by_name(default_branch).present?
    end

    def default_branch
      project.default_branch
    end

    def push_access_level
      if default_branch_protection.no_one_can_push?
        Gitlab::Access::NO_ACCESS
      elsif default_branch_protection.developer_can_push?
        Gitlab::Access::DEVELOPER
      elsif default_branch_protection.maintainer_can_push?
        Gitlab::Access::MAINTAINER
      else
        Gitlab::Access::ADMIN
      end
    end

    def merge_access_level
      if default_branch_protection.no_one_can_merge?
        Gitlab::Access::NO_ACCESS
      elsif default_branch_protection.developer_can_merge?
        Gitlab::Access::DEVELOPER
      elsif default_branch_protection.maintainer_can_merge?
        Gitlab::Access::MAINTAINER
      else
        Gitlab::Access::ADMIN
      end
    end
  end
end

Projects::ProtectDefaultBranchService.prepend_mod
