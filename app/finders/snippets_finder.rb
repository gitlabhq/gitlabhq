class SnippetsFinder < UnionFinder
  attr_accessor :current_user, :params

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = init_collection
    items = by_project(items)
    items = by_author(items)
    items = by_visibility(items)

    items.fresh
  end

  private

  def init_collection
    items = Snippet.all

    accessible(items)
  end

  def accessible(items)
    segments = []
    segments << items.public_to_user(current_user)
    segments << authorized_to_user(items)  if current_user

    find_union(segments, Snippet.includes(:author))
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

  def by_project(items)
    return items unless params[:project]

    items.where(project_id: params[:project].id)
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
