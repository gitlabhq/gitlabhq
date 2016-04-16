# == FilterProjects
#
# Controller concern to handle projects filtering
# * by name
# * by archived state
#
module FilterProjects
  extend ActiveSupport::Concern

  def filter_projects(projects)
    projects = projects.search(params[:filter_projects]) if params[:filter_projects].present?
    projects = projects.non_archived if params[:archived].blank?

    if params[:personal].present? and current_user
      projects = projects.personal(current_user)
    end

    projects
  end
end
