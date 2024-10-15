# frozen_string_literal: true

module Projects
  module ErrorTracking
    class ProjectsController < Projects::ApplicationController
      respond_to :json

      before_action :authorize_admin_sentry!

      feature_category :observability
      urgency :low

      def index
        service = ::ErrorTracking::ListProjectsService.new(
          project,
          current_user,
          list_projects_params
        )
        result = service.execute

        if result[:status] == :success
          render json: { projects: serialize_projects(result[:projects]) }
        else
          render(
            status: result[:http_status] || :bad_request,
            json: { message: result[:message] }
          )
        end
      end

      private

      def list_projects_params
        { api_host: params[:api_host], token: params[:token] }
      end

      def serialize_projects(projects)
        ::ErrorTracking::ProjectSerializer
          .new(project: project, user: current_user)
          .represent(projects)
      end
    end
  end
end
