# frozen_string_literal: true

module Clusters
  module Management
    class ValidateManagementProjectPermissionsService
      attr_reader :current_user

      def initialize(user = nil)
        @current_user = user
      end

      def execute(cluster, management_project_id)
        if management_project_id.present?
          management_project = management_project_scope(cluster).find_by_id(management_project_id)

          unless management_project && can_admin_pipeline_for_project?(management_project)
            cluster.errors.add(:management_project_id, _('Project does not exist or you don\'t have permission to perform this action'))

            return false
          end
        end

        true
      end

      private

      def can_admin_pipeline_for_project?(project)
        Ability.allowed?(current_user, :admin_pipeline, project)
      end

      def management_project_scope(cluster)
        return ::Project.all if cluster.instance_type?

        group =
          if cluster.group_type?
            cluster.first_group
          elsif cluster.project_type?
            cluster.first_project&.namespace
          end

        # Prevent users from selecting nested projects until
        # https://gitlab.com/gitlab-org/gitlab/issues/34650 is resolved
        include_subgroups = cluster.group_type?

        ::GroupProjectsFinder.new(
          group: group,
          current_user: current_user,
          options: { exclude_shared: true, include_subgroups: include_subgroups }
        ).execute
      end
    end
  end
end
