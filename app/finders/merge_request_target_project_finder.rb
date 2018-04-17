class MergeRequestTargetProjectFinder
  include FinderMethods

  attr_reader :current_user, :source_project

  def initialize(current_user: nil, source_project:)
    @current_user = current_user
    @source_project = source_project
  end

  def execute
    if @source_project.fork_network
      @source_project.fork_network.projects
        .public_or_visible_to_user(current_user)
        .non_archived
        .with_feature_available_for_user(:merge_requests, current_user)
    else
      Project.where(id: source_project)
    end
  end
end
