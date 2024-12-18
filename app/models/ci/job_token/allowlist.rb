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
        group_links_for_target(target_project).any?
      end

      def nearest_scope_for_target_project(target_project)
        source_links.with_target(target_project).first ||
          group_links_for_target(target_project).first
      end

      def projects
        Project.from_union(target_projects, remove_duplicates: false)
      end

      def groups
        ::Group.id_in(group_links.pluck(:target_group_id))
      end

      def add!(target_project, user:, default_permissions: true, policies: [])
        job_token_policies = add_policies_to_ci_job_token_enabled ? policies : []
        default_permissions = add_policies_to_ci_job_token_enabled ? default_permissions : true

        Ci::JobToken::ProjectScopeLink.create!(
          source_project: @source_project,
          direction: @direction,
          target_project: target_project,
          added_by: user,
          default_permissions: default_permissions,
          job_token_policies: job_token_policies
        )
      end

      def add_group!(target_group, user:, default_permissions: true, policies: [])
        job_token_policies = add_policies_to_ci_job_token_enabled ? policies : []
        default_permissions = add_policies_to_ci_job_token_enabled ? default_permissions : true

        Ci::JobToken::GroupScopeLink.create!(
          source_project: @source_project,
          target_group: target_group,
          added_by: user,
          default_permissions: default_permissions,
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

      def group_links_for_target(target_project)
        target_group_ids = target_project.parent_groups.pluck(:id)
        group_links.where(target_group_id: target_group_ids).order(
          Arel.sql(
            "array_position(ARRAY#{target_group_ids}::bigint[], ci_job_token_group_scope_links.target_group_id)"
          )
        )
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
