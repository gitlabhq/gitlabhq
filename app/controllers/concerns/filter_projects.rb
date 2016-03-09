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
    projects
  end
end
