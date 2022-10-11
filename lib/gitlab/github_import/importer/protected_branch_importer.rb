# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ProtectedBranchImporter
        attr_reader :protected_branch, :project, :client

        # protected_branch - An instance of
        #   `Gitlab::GithubImport::Representation::ProtectedBranch`.
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(protected_branch, project, client)
          @protected_branch = protected_branch
          @project = project
          @client = client
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

        def params
          {
            name: protected_branch.id,
            push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
            merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
            allow_force_push: allow_force_push?
          }
        end

        def allow_force_push?
          if ProtectedBranch.protected?(project, protected_branch.id)
            ProtectedBranch.allow_force_push?(project, protected_branch.id) && protected_branch.allow_force_pushes
          else
            protected_branch.allow_force_pushes
          end
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
          return unless project.licensed_feature_available?(:push_rules)
          return unless protected_branch.required_signatures

          push_rule = project.push_rule || project.build_push_rule
          push_rule.update!(reject_unsigned_commits: true)
          project.project_setting.update!(push_rule_id: push_rule.id)
        end
      end
    end
  end
end
