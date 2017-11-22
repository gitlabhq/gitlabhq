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
    items = by_scope(items)
    items = by_author(items)
    items = by_visibility(items)

    items.fresh
  end

  private

  def init_collection
    if params[:project].present?
      if can?(current_user, :read_project_snippet, params[:project])
        ProjectSnippet.where(project_id: params[:project].id)
      else
        Snippet.none
      end
    else
      Snippet.where(feature_available_projects)
    end
  end

  def feature_available_projects
    table[:project_id].in(authorized_project_ids).or(not_project_related)
  end

  def authorized_project_ids
    Project.with_feature_available_for_user(:snippets, current_user).select(:id).map(&:id)
  end

  def not_project_related
    table[:project_id].eq(nil)
  end

  def table
    Snippet.arel_table
  end

  def by_scope(items)
    segments = []
    segments << public_to_user(items)
    segments << authorized_to_user(items) if current_user

    find_union(segments, Snippet)
  end

  def public_to_user(items)
    if params[:project].present? && params[:project].project_member(current_user)
      items
    else
      items.public_to_user(current_user)
    end
  end

  def authorized_to_user(items)
    items.where(
      'author_id = :author_id
       OR project_id IN (:project_ids)',
       author_id: current_user.id,
       project_ids: current_user.authorized_projects.select(:id))
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
