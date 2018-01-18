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
  attr_accessor :current_user, :params, :project

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
    Snippet.where(feature_available_projects.or(not_project_related)).public_or_visible_to_user(current_user)
  end

  def feature_available_projects
    projects = Project.public_or_visible_to_user(current_user)
      .with_feature_available_for_user(:snippets, current_user).select(:id)
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
