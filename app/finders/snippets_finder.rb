# Snippets Finder
#
# Used to filter Snippets collections by a set of params
#
# Arguments.
#
# current_user - The current user, nil also can be used.
# params:
#   visibility (integer) - Individual snippet visibility: Public(20), internal(10) or private(0).
#   project (Project) - Project related.
#   author (User) - Author related.
#
# params are optional
class SnippetsFinder < UnionFinder
  include Gitlab::Allowable
  include FinderMethods

  attr_accessor :current_user, :project, :params

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
    @project = params[:project]
  end

  def execute
    items = init_collection
    items = by_author(items)
    items = by_visibility(items)

    items.fresh
  end

  private

  def init_collection
    if project.present?
      authorized_snippets_from_project
    else
      authorized_snippets
    end
  end

  def authorized_snippets_from_project
    if can?(current_user, :read_project_snippet, project)
      if project.team.member?(current_user)
        project.snippets
      else
        project.snippets.public_to_user(current_user)
      end
    else
      Snippet.none
    end
  end

  def authorized_snippets
    Snippet.where(feature_available_projects.or(not_project_related))
      .public_or_visible_to_user(current_user)
  end

  # Returns a collection of projects that is either public or visible to the
  # logged in user.
  #
  # A caller must pass in a block to modify individual parts of
  # the query, e.g. to apply .with_feature_available_for_user on top of it.
  # This is useful for performance as we can stick those additional filters
  # at the bottom of e.g. the UNION.
  def projects_for_user
    return yield(Project.public_to_user) unless current_user

    # If the current_user is allowed to see all projects,
    # we can shortcut and just return.
    return yield(Project.all) if current_user.full_private_access?

    authorized_projects = yield(Project.where('EXISTS (?)', current_user.authorizations_for_projects))

    levels = Gitlab::VisibilityLevel.levels_for_user(current_user)
    visible_projects = yield(Project.where(visibility_level: levels))

    # We use a UNION here instead of OR clauses since this results in better
    # performance.
    union = Gitlab::SQL::Union.new([authorized_projects.select('projects.id'), visible_projects.select('projects.id')])

    Project.from("(#{union.to_sql}) AS #{Project.table_name}")
  end

  def feature_available_projects
    # Don't return any project related snippets if the user cannot read cross project
    return table[:id].eq(nil) unless Ability.allowed?(current_user, :read_cross_project)

    projects = projects_for_user do |part|
      part.with_feature_available_for_user(:snippets, current_user)
    end.select(:id)

    arel_query = Arel::Nodes::SqlLiteral.new(projects.to_sql)
    table[:project_id].in(arel_query)
  end

  def not_project_related
    table[:project_id].eq(nil)
  end

  def table
    Snippet.arel_table
  end

  def by_visibility(items)
    visibility = params[:visibility] || visibility_from_scope

    return items unless visibility

    items.where(visibility_level: visibility)
  end

  def by_author(items)
    return items unless params[:author]

    items.where(author_id: params[:author].id)
  end

  def visibility_from_scope
    case params[:scope].to_s
    when 'are_private'
      Snippet::PRIVATE
    when 'are_internal'
      Snippet::INTERNAL
    when 'are_public'
      Snippet::PUBLIC
    else
      nil
    end
  end
end
