# frozen_string_literal: true

class MergeRequestTargetProjectFinder
  include FinderMethods

  attr_reader :current_user, :source_project

  def initialize(current_user: nil, source_project:, project_feature: :merge_requests)
    @current_user = current_user
    @source_project = source_project
    @project_feature = project_feature
  end

  def execute(include_routes: false)
    if source_project.fork_network
      include_routes ? projects.inc_routes : projects
    else
      Project.id_in(source_project.id)
    end
  end

  private

  attr_reader :project_feature

  def projects
    source_project
      .fork_network
      .projects
      .public_or_visible_to_user(current_user)
      .non_archived
      .with_feature_available_for_user(project_feature, current_user)
  end
end
