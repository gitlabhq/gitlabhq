# ProjectsFinder
#
# Used to filter Projects  by set of params
#
# Arguments:
#   current_user - which user use
#   project_ids_relation: int[] - project ids to use
#   params:
#     trending: boolean
#     owned: boolean
#     non_public: boolean
#     starred: boolean
#     sort: string
#     visibility_level: int
#     tags: string[]
#     personal: boolean
#     search: string
#     non_archived: boolean
#
class ProjectsFinder < UnionFinder
  attr_accessor :params
  attr_reader :current_user, :project_ids_relation

  def initialize(params: {}, current_user: nil, project_ids_relation: nil)
    @params = params
    @current_user = current_user
    @project_ids_relation = project_ids_relation
  end

  def execute
    items = init_collection
    items = items.map do |item|
      item = by_ids(item)
      item = by_personal(item)
      item = by_starred(item)
      item = by_trending(item)
      item = by_visibilty_level(item)
      item = by_tags(item)
      item = by_search(item)
      by_archived(item)
    end
    items = union(items)
    sort(items)
  end

  private

  def init_collection
    projects = []

    if params[:owned].present?
      projects << current_user.owned_projects if current_user
    else
      projects << current_user.authorized_projects if current_user
      projects << Project.unscoped.public_to_user(current_user) unless params[:non_public].present?
    end

    projects
  end

  def by_ids(items)
    project_ids_relation ? items.where(id: project_ids_relation) : items
  end

  def union(items)
    find_union(items, Project).with_route
  end

  def by_personal(items)
    (params[:personal].present? && current_user) ? items.personal(current_user) : items
  end

  def by_starred(items)
    (params[:starred].present? && current_user) ? items.starred_by(current_user) : items
  end

  def by_trending(items)
    params[:trending].present? ? items.trending : items
  end

  def by_visibilty_level(items)
    params[:visibility_level].present? ? items.where(visibility_level: params[:visibility_level]) : items
  end

  def by_tags(items)
    params[:tag].present? ? items.tagged_with(params[:tag]) : items
  end

  def by_search(items)
    params[:search] ||= params[:name]
    params[:search].present? ? items.search(params[:search]) : items
  end

  def sort(items)
    params[:sort].present? ? items.sort(params[:sort]) : items
  end

  def by_archived(projects)
    # Back-compatibility with the places where `params[:archived]` can be set explicitly to `false`
    params[:non_archived] = !Gitlab::Utils.to_boolean(params[:archived]) if params.key?(:archived)

    params[:non_archived] ? projects.non_archived : projects
  end
end
