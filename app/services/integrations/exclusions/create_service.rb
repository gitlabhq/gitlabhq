# frozen_string_literal: true

# Exclusions are custom settings at the group or project level used to selectively deactivate an instance integration
# https://gitlab.com/gitlab-org/gitlab/-/issues/454372
module Integrations
  module Exclusions
    class CreateService < BaseService
      MAX_PROJECTS = 100
      MAX_GROUPS = 100

      def execute
        result = validate
        return result if result.present?

        return ServiceResponse.error(message: 'project limit exceeded') if projects_over_limit?
        return ServiceResponse.error(message: 'group limit exceeded') if groups_over_limit?

        project_integrations = create_project_integrations
        group_integrations = create_group_integrations
        ServiceResponse.success(payload: group_integrations + project_integrations)
      end

      private

      def create_project_integrations
        projects = filtered_projects
        return Integration.none unless projects.present?

        integration_attrs = projects.map do |project|
          {
            project_id: project.id,
            type_new: integration_type,
            active: false,
            inherit_from_id: nil
          }
        end

        result = Integration.upsert_all(integration_attrs, unique_by: [:project_id, :type_new])
        Integration.id_in(result.rows.flatten)
      end

      def create_group_integrations
        groups = filtered_groups
        return Integration.none unless groups.present?

        integrations_for_groups = integration_model.for_group(groups)
        existing_group_ids = integrations_for_groups.map(&:group_id).to_set
        groups_missing_integrations = groups.reject do |g|
          existing_group_ids.include?(g.id)
        end

        integrations_to_update = integrations_for_groups.select do |integration|
          integration.inherit_from_id.present? || integration.activated?
        end
        integration_ids_to_update = integrations_to_update.map(&:id)
        integration_model.id_in(integration_ids_to_update).update_all(inherit_from_id: nil, active: false)

        integration_attrs = groups_missing_integrations.map do |g|
          {
            group_id: g.id,
            active: false,
            inherit_from_id: nil,
            type_new: integration_type
          }
        end

        created_group_integration_ids = []
        if integration_attrs.present?
          created_group_integration_ids = Integration.insert_all(integration_attrs,
            returning: :id).rows.flatten
        end

        new_exclusions = Integration.id_in(integration_ids_to_update + created_group_integration_ids)
        new_exclusions.each do |integration|
          PropagateIntegrationWorker.perform_async(integration.id)
        end
        new_exclusions
      end

      # Exclusions for groups should propagate to subgroup children
      # Skip creating integrations for subgroups and projects that would already be deactivated by an ancestor
      # integration.
      # Also skip for projects and groups that would be deactivated by creating an integration for another group in the
      # same call to #execute.
      def filtered_groups
        group_ids = groups.map(&:id) + ancestor_integration_group_ids
        groups.reject do |g|
          g.ancestor_ids.intersect?(group_ids)
        end
      end
      strong_memoize_attr :filtered_groups

      def filtered_projects
        filtered_group_ids = filtered_groups.map(&:id) + ancestor_integration_group_ids

        projects.reject do |p|
          p&.group&.self_and_ancestor_ids&.intersect?(filtered_group_ids)
        end
      end
      strong_memoize_attr :filtered_projects

      def ancestor_integration_group_ids
        integration_model
          .with_custom_settings
          .for_group(
            (groups.flat_map(&:traversal_ids) + projects.flat_map { |p| p&.group&.traversal_ids }).compact.uniq
          ).limit(MAX_GROUPS + MAX_PROJECTS)
          .pluck_group_id
      end
      strong_memoize_attr :ancestor_integration_group_ids

      def projects_over_limit?
        projects.size > MAX_PROJECTS
      end

      def groups_over_limit?
        groups.size > MAX_GROUPS
      end
    end
  end
end
