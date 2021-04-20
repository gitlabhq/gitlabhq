# frozen_string_literal: true

module Groups
  class SharedProjectsController < Groups::ApplicationController
    respond_to :json
    before_action :group
    skip_cross_project_access_check :index

    feature_category :subgroups

    def index
      shared_projects = GroupProjectsFinder.new(
        group: group,
        current_user: current_user,
        params: finder_params,
        options: { only_shared: true }
      ).execute
      serializer = GroupChildSerializer.new(current_user: current_user)
                     .with_pagination(request, response)

      render json: serializer.represent(shared_projects)
    end

    private

    def finder_params
      @finder_params ||= begin
        # Make the `search` param consistent for the frontend,
        # which will be using `filter`.
        params[:search] ||= params[:filter] if params[:filter]
        # Don't show archived projects
        params[:non_archived] = true
        params.permit(:sort, :search, :non_archived)
      end
    end
  end
end
