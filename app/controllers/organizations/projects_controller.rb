# frozen_string_literal: true

module Organizations
  class ProjectsController < ApplicationController
    before_action :authorize_project_view_edit_page!, only: [:edit]

    feature_category :cell

    def edit; end

    private

    def project
      @project = Project.find_by_full_path(
        [safe_params[:namespace_id], '/', safe_params[:id]].join('')
      )
    end

    def authorize_project_view_edit_page!
      access_denied! unless can?(current_user, :view_edit_page, project)
    end

    def safe_params
      params.permit(:id, :namespace_id)
    end
  end
end
