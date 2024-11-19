# frozen_string_literal: true
module Ci
  module JobToken
    class Allowlist
      def initialize(source_project, direction: :inbound)
        @source_project = source_project
        @direction = direction
      end

      def includes_project?(target_project)
        source_links
          .with_target(target_project)
          .exists?
      end

      def includes_group?(target_project)
        allowlist_group_ids = group_links.pluck(:target_group_id)
        target_project_group_path_ids = target_project.parent_groups.map(&:id)

        allowed_target_group_ids = allowlist_group_ids & target_project_group_path_ids

        allowed_target_group_ids.any?
      end

      def projects
        Project.from_union(target_projects, remove_duplicates: false)
      end

      def groups
        ::Group.id_in(group_links.pluck(:target_group_id))
      end

      def add!(target_project, user:, policies: [])
        job_token_policies = add_policies_to_ci_job_token_enabled ? policies : []

        Ci::JobToken::ProjectScopeLink.create!(
          source_project: @source_project,
          direction: @direction,
          target_project: target_project,
          added_by: user,
          job_token_policies: job_token_policies
        )
      end

      def add_group!(target_group, user:, policies: [])
        job_token_policies = add_policies_to_ci_job_token_enabled ? policies : []

        Ci::JobToken::GroupScopeLink.create!(
          source_project: @source_project,
          target_group: target_group,
          added_by: user,
          job_token_policies: job_token_policies
        )
      end

      private

      def add_policies_to_ci_job_token_enabled
        Feature.enabled?(:add_policies_to_ci_job_token, @source_project)
      end

      def source_links
        Ci::JobToken::ProjectScopeLink
          .with_source(@source_project)
          .where(direction: @direction)
      end

      def group_links
        Ci::JobToken::GroupScopeLink
          .with_source(@source_project)
      end

      def target_project_ids
        source_links
          # pluck needed to avoid ci and main db join
          .pluck(:target_project_id)
      end

      def target_projects
        [
          Project.id_in(@source_project),
          Project.id_in(target_project_ids)
        ]
      end
    end
  end
end
