# frozen_string_literal: true

module RendersProjectsList
  include RendersMemberAccess

  def prepare_projects_for_rendering(projects)
    preload_max_member_access_for_collection(Project, projects)
    preload_member_roles(projects) if current_user

    # Call the count methods on every project, so the BatchLoader would load them all at
    # once when the entities are rendered
    projects.each(&:forks_count)
    projects.each(&:open_issues_count)
    projects.each(&:open_merge_requests_count)

    projects
  end

  def preload_member_roles(projects)
    # overridden in EE
  end
end

RendersProjectsList.prepend_mod
