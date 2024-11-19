# frozen_string_literal: true

class MergeRequestTargetProjectFinder
  include FinderMethods

  attr_reader :current_user, :source_project

  def initialize(source_project:, current_user: nil, project_feature: :merge_requests)
    @current_user = current_user
    @source_project = source_project
    @project_feature = project_feature
  end

  def execute(search: nil, include_routes: false, include_fork_networks: false)
    if source_project.fork_network
      items = include_routes ? projects.inc_routes : projects
      items = include_fork_networks ? items.include_fork_networks : items
      by_search(items, search).allow_cross_joins_across_databases(
        url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
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

  # rubocop: disable CodeReuse/ActiveRecord
  def by_search(items, search)
    items.joins(:route).fuzzy_search(search, [Route.arel_table[:path], Route.arel_table[:name], :description])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

MergeRequestTargetProjectFinder.prepend_mod_with("MergeRequestTargetProjectFinder")
