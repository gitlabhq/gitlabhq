# frozen_string_literal: true
module Ci
  module JobToken
    class Allowlist
      include ::Gitlab::Utils::StrongMemoize

      def initialize(source_project, direction: :inbound)
        @source_project = source_project
        @direction = direction
      end

      def includes_project?(target_project)
        project_links
          .with_target(target_project)
          .exists?
      end

      def includes_group?(target_project)
        group_links_for_target(target_project).any?
      end

      def nearest_scope_for_target_project(target_project)
        project_links.with_target(target_project).first ||
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

      def project_link_traversal_ids
        project_links.includes(target_project: :project_namespace).map do |p|
          p.target_project.project_namespace.traversal_ids
        end
      end

      def group_link_traversal_ids
        group_links.includes(:target_group).map { |g| g.target_group.traversal_ids }
      end

      def autopopulated_project_global_ids
        project_links.autopopulated.map { |link| link.target_project.to_global_id }.uniq
      end

      def autopopulated_group_global_ids
        group_links.autopopulated.map { |link| link.target_group.to_global_id }.uniq
      end

      def project_links
        Ci::JobToken::ProjectScopeLink
          .with_source(@source_project)
          .where(direction: @direction)
      end

      def group_links
        Ci::JobToken::GroupScopeLink
          .with_source(@source_project)
      end

      def bulk_add_projects!(target_projects, user:, autopopulated: false, policies: [])
        now = Time.zone.now
        job_token_policies = add_policies_to_ci_job_token_enabled ? policies : []

        projects = target_projects.map do |target_project|
          Ci::JobToken::ProjectScopeLink.new(
            source_project_id: @source_project.id,
            target_project: target_project,
            autopopulated: autopopulated,
            added_by: user,
            job_token_policies: job_token_policies,
            direction: @direction,
            created_at: now
          )
        end

        Ci::JobToken::ProjectScopeLink.bulk_insert!(projects)
      end

      def bulk_add_groups!(target_groups, user:, autopopulated: false, policies: [])
        now = Time.zone.now
        job_token_policies = add_policies_to_ci_job_token_enabled ? policies : []

        groups = target_groups.map do |target_group|
          Ci::JobToken::GroupScopeLink.new(
            source_project_id: @source_project.id,
            target_group: target_group,
            autopopulated: autopopulated,
            added_by: user,
            job_token_policies: job_token_policies,
            created_at: now
          )
        end

        Ci::JobToken::GroupScopeLink.bulk_insert!(groups)
      end

      private

      def add_policies_to_ci_job_token_enabled
        Feature.enabled?(:add_policies_to_ci_job_token, @source_project)
      end
      strong_memoize_attr :add_policies_to_ci_job_token_enabled

      def group_links_for_target(target_project)
        target_group_ids = target_project.parent_groups.pluck(:id)
        group_links.where(target_group_id: target_group_ids).order(
          Arel.sql(
            "array_position(ARRAY#{target_group_ids}::bigint[], ci_job_token_group_scope_links.target_group_id)"
          )
        )
      end

      def target_project_ids
        project_links
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
