# frozen_string_literal: true

# Projects::RedirectController is used to resolve the route projects/:id.
# It's helpful for this to be in its own controller so that the
# ProjectsController can assume that :namespace_id exists
class Projects::RedirectController < ::ApplicationController
  skip_before_action :authenticate_user!

  feature_category :groups_and_projects

  def redirect_from_id
    project = Project.find(params[:id])

    if can?(current_user, :read_project, project)
      redirect_to project
    else
      render_404
    end
  end
end
