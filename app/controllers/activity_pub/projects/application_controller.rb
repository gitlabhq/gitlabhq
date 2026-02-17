# frozen_string_literal: true

module ActivityPub
  module Projects
    class ApplicationController < ::ActivityPub::ApplicationController
      before_action :project
      before_action :ensure_project_feature_flag

      private

      def project
        return unless permitted_params[:project_id] || permitted_params[:id]

        path = File.join(permitted_params[:namespace_id], permitted_params[:project_id] || permitted_params[:id])

        @project = find_routable!(Project, path, request.fullpath, extra_authorization_proc: auth_proc)
      end

      def auth_proc
        ->(project) { project.public? && !project.deletion_in_progress? }
      end

      def ensure_project_feature_flag
        not_found unless ::Feature.enabled?(:activity_pub_project, project)
      end

      def permitted_params
        params.permit(:id, :namespace_id, :project_id)
      end
    end
  end
end
