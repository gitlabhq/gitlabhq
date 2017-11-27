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
  attr_accessor :current_user, :params

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = init_collection
    items = by_authorization(items)
    items = by_author(items)
    items = by_visibility(items)

    items.fresh
  end

  private

  def init_collection
    if params[:project].present?
      if can?(current_user, :read_project_snippet, params[:project])
        params[:project].snippets
      else
        Snippet.none
      end
    else
      Snippet.where(visible_snippets)
    end
  end

  def visible_snippets
    table[:project_id]
      .in(feature_available_projects)
      .or(not_project_related)
  end

  def feature_available_projects
    projects = Project.with_feature_available_for_user(:snippets, current_user).select(:id)
    Arel::Nodes::SqlLiteral.new(projects.to_sql)
  end

  def not_project_related
    table[:project_id].eq(nil)
  end

  def table
    Snippet.arel_table
  end

  def by_authorization(items)
    segments = []
    segments << snippets_from_authorized_projects(items) if current_user && !params[:project].present?
    segments << authorized_snippets_to_user(items)
    find_union(segments, Snippet)
  end

  def snippets_from_authorized_projects(items)
    items.where(
      'author_id = :author_id
       OR project_id IN (:project_ids)',
       author_id: current_user.id,
       project_ids: current_user.authorized_projects.select(:id))
  end

  def authorized_snippets_to_user(items)
    if params[:project].present? && project_member?
      items
    else
      items.where(snippets_from_public_projects).public_to_user(current_user)
    end
  end

  def project_member?
    params[:project].project_member(current_user) ||
      params[:project].team&.member?(current_user)
  end

  def snippets_from_public_projects
    table[:project_id]
      .in(projects_public_to_user)
      .or(not_project_related)
  end

  def projects_public_to_user
    projects = Project.public_to_user(current_user).select(:id)
    Arel::Nodes::SqlLiteral.new(projects.to_sql)
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
