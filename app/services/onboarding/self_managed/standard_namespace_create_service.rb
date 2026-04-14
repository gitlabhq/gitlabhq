# frozen_string_literal: true

module Onboarding
  module SelfManaged
    class StandardNamespaceCreateService
      include BaseServiceUtility

      def initialize(user, group_params:, project_params:)
        @current_user = user
        @group_params = group_params.dup
        @project_params = project_params.dup
      end

      def execute
        if group_params[:path].blank? && group_params[:name].present?
          group_params[:path] = Namespace.clean_path(group_params[:name])
        end

        response = Groups::CreateService.new(current_user, group_params).execute
        group = response[:group]

        unless group.persisted?
          return ServiceResponse.error(
            message: s_('Onboarding|Group failed to be created'),
            payload: { group: group, project: Project.new(project_params) }
          )
        end

        project = create_project(group)

        unless project.persisted?
          return ServiceResponse.error(
            message: s_('Onboarding|Project failed to be created'),
            payload: { group: group, project: project }
          )
        end

        ServiceResponse.success(payload: { project: project, group: project.namespace })
      end

      private

      attr_reader :current_user, :group_params, :project_params

      def create_project(group)
        merged_params = project_params.merge(namespace_id: group.id, organization_id: group.organization_id)

        Projects::CreateService.new(current_user, merged_params).execute
      end
    end
  end
end
