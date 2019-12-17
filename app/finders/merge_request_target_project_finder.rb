# frozen_string_literal: true

class MergeRequestTargetProjectFinder
  include FinderMethods

  attr_reader :current_user, :source_project

  def initialize(current_user: nil, source_project:)
    @current_user = current_user
    @source_project = source_project
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute(include_routes: false)
    if source_project.fork_network
      include_routes ? projects.inc_routes : projects
    else
      Project.where(id: source_project)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def projects
    source_project
      .fork_network
      .projects
      .public_or_visible_to_user(current_user)
      .non_archived
      .with_feature_available_for_user(:merge_requests, current_user)
  end
end
