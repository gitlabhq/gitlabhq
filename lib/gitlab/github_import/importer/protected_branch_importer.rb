# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ProtectedBranchImporter
        attr_reader :project

        # By default on GitHub, both developers and maintainers can merge
        # a PR into the protected branch
        GITHUB_DEFAULT_MERGE_ACCESS_LEVEL = Gitlab::Access::DEVELOPER

        # protected_branch - An instance of
        #   `Gitlab::GithubImport::Representation::ProtectedBranch`.
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(protected_branch, project, client)
          @protected_branch = protected_branch
          @project = project
          @client = client
          @user_finder = GithubImport::UserFinder.new(project, client)
        end

        def execute
          # The creator of the project is always allowed to create protected
          # branches, so we skip the authorization check in this service class.
          ProtectedBranches::CreateService
            .new(project, project.creator, params)
            .execute(skip_authorization: true)

          update_project_settings if default_branch?
        end

        private

        attr_reader :protected_branch, :user_finder

        def params
          {
            name: protected_branch.id,
            push_access_levels_attributes: push_access_levels_attributes,
            merge_access_levels_attributes: merge_access_levels_attributes,
            allow_force_push: allow_force_push?,
            code_owner_approval_required: code_owner_approval_required?
          }
        end

        def allow_force_push?
          return false unless protected_branch.allow_force_pushes

          if protected_on_gitlab?
            ProtectedBranch.allow_force_push?(project, protected_branch.id)
          elsif default_branch?
            !default_branch_protection.any?
          else
            true
          end
        end

        def code_owner_approval_required?
          return false unless licensed_feature_available?(:code_owner_approval_required)

          return protected_branch.require_code_owner_reviews unless protected_on_gitlab?

          # Gets the strictest require_code_owner rule between GitHub and GitLab
          protected_branch.require_code_owner_reviews ||
            ProtectedBranch.branch_requires_code_owner_approval?(
              project,
              protected_branch.id
            )
        end

        def default_branch?
          protected_branch.id == project.default_branch
        end

        def update_project_settings
          update_setting_for_only_allow_merge_if_all_discussions_are_resolved
          update_project_push_rule
        end

        def update_setting_for_only_allow_merge_if_all_discussions_are_resolved
          return unless protected_branch.required_conversation_resolution

          project.update(only_allow_merge_if_all_discussions_are_resolved: true)
        end

        def update_project_push_rule
          return unless licensed_feature_available?(:push_rules)
          return unless protected_branch.required_signatures

          push_rule = project.push_rule || project.build_push_rule
          push_rule.update!(reject_unsigned_commits: true)
          project.project_setting.update!(push_rule_id: push_rule.id)
        end

        def push_access_levels_attributes
          if allowed_to_push_gitlab_user_ids.present?
            @allowed_to_push_gitlab_user_ids.map { |user_id| { user_id: user_id } }
          elsif protected_branch.required_pull_request_reviews
            [{ access_level: Gitlab::Access::NO_ACCESS }]
          else
            [{ access_level: gitlab_access_level_for(:push) }]
          end
        end

        def merge_access_levels_attributes
          [{ access_level: merge_access_level }]
        end

        def allowed_to_push_gitlab_user_ids
          return if protected_branch.allowed_to_push_users.empty? ||
            !licensed_feature_available?(:protected_refs_for_users)

          @allowed_to_push_gitlab_user_ids = []

          protected_branch.allowed_to_push_users.each do |github_user_data|
            gitlab_user_id = user_finder.user_id_for(github_user_data)
            next unless gitlab_user_id

            @allowed_to_push_gitlab_user_ids << gitlab_user_id
          end

          @allowed_to_push_gitlab_user_ids &= project_member_ids
        end

        # Gets the strictest merge_access_level between GitHub and GitLab
        def merge_access_level
          gitlab_access = gitlab_access_level_for(:merge)

          return gitlab_access if gitlab_access == Gitlab::Access::NO_ACCESS

          [gitlab_access, GITHUB_DEFAULT_MERGE_ACCESS_LEVEL].max
        end

        # action - :push/:merge
        def gitlab_access_level_for(action)
          if default_branch?
            action == :push ? default_branch_push_access_level : default_branch_merge_access_level
          elsif protected_on_gitlab?
            non_default_branch_access_level_for(action)
          else
            gitlab_default_access_level_for(action)
          end
        end

        def default_branch_push_access_level
          if default_branch_protection.any? && default_branch_protection.developer_can_push?
            Gitlab::Access::DEVELOPER
          else
            gitlab_default_access_level_for(:push)
          end
        end

        def default_branch_merge_access_level
          if default_branch_protection.any? && default_branch_protection.developer_can_merge?
            Gitlab::Access::DEVELOPER
          else
            gitlab_default_access_level_for(:merge)
          end
        end

        def default_branch_protection
          if Feature.enabled?(:default_branch_protection_defaults, project)
            Gitlab::Access::DefaultBranchProtection.new(project)
          else
            Gitlab::Access::BranchProtection.new(project.namespace.default_branch_protection)
          end
        end

        def protected_on_gitlab?
          ProtectedBranch.protected?(project, protected_branch.id)
        end

        def non_default_branch_access_level_for(action)
          access_level = ProtectedBranch.access_levels_for_ref(protected_branch.id, action: action)
                                        .find(&:role?)&.access_level

          access_level || gitlab_default_access_level_for(action)
        end

        def gitlab_default_access_level_for(action)
          return ProtectedBranch::PushAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL if action == :push

          ProtectedBranch::MergeAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL
        end

        def licensed_feature_available?(feature)
          project.licensed_feature_available?(feature)
        end

        def project_member_ids
          project.authorized_users.map(&:id)
        end
      end
    end
  end
end
