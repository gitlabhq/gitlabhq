# frozen_string_literal: true

module Organizations
  class ProjectsController < ApplicationController
    before_action :authorize_project_view_edit_page!, only: [:edit]

    feature_category :cell

    def edit; end

    private

    def project
      @project = Project.find_by_full_path(
        [params[:namespace_id], '/', params[:id]].join('')
      )
    end

    def authorize_project_view_edit_page!
      access_denied! unless can?(current_user, :view_edit_page, project)
    end
  end
end
