# frozen_string_literal: true

module ActivityPub
  module Projects
    class ApplicationController < ::ActivityPub::ApplicationController
      before_action :project
      before_action :ensure_project_feature_flag

      private

      def project
        return unless params[:project_id] || params[:id]

        path = File.join(params[:namespace_id], params[:project_id] || params[:id])

        @project = find_routable!(Project, path, request.fullpath, extra_authorization_proc: auth_proc)
      end

      def auth_proc
        ->(project) { project.public? && !project.pending_delete? }
      end

      def ensure_project_feature_flag
        not_found unless ::Feature.enabled?(:activity_pub_project, project)
      end
    end
  end
end
