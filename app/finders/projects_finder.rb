# frozen_string_literal: true

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
#     archived: 'only' or boolean
#     min_access_level: integer
#
class ProjectsFinder < UnionFinder
  include CustomAttributesFilter

  attr_accessor :params
  attr_reader :current_user, :project_ids_relation

  def initialize(params: {}, current_user: nil, project_ids_relation: nil)
    @params = params
    @current_user = current_user
    @project_ids_relation = project_ids_relation
  end

  def execute
    user = params.delete(:user)
    collection =
      if user
        PersonalProjectsFinder.new(user, finder_params).execute(current_user) # rubocop: disable CodeReuse/Finder
      else
        init_collection
      end

    collection = filter_projects(collection)
    sort(collection)
  end

  private

  def init_collection
    if current_user
      collection_with_user
    else
      collection_without_user
    end
  end

  # EE would override this to add more filters
  def filter_projects(collection)
    collection = by_ids(collection)
    collection = by_personal(collection)
    collection = by_starred(collection)
    collection = by_trending(collection)
    collection = by_visibility_level(collection)
    collection = by_tags(collection)
    collection = by_search(collection)
    collection = by_archived(collection)
    collection = by_custom_attributes(collection)
    collection = by_deleted_status(collection)
    collection
  end

  def collection_with_user
    if owned_projects?
      current_user.owned_projects
    elsif min_access_level?
      current_user.authorized_projects(params[:min_access_level])
    else
      if private_only?
        current_user.authorized_projects
      else
        Project.public_or_visible_to_user(current_user)
      end
    end
  end

  # Builds a collection for an anonymous user.
  def collection_without_user
    if private_only? || owned_projects? || min_access_level?
      Project.none
    else
      Project.public_to_user
    end
  end

  def owned_projects?
    params[:owned].present?
  end

  def private_only?
    params[:non_public].present?
  end

  def min_access_level?
    params[:min_access_level].present?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_ids(items)
    project_ids_relation ? items.where(id: project_ids_relation) : items
  end
  # rubocop: enable CodeReuse/ActiveRecord

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

  # rubocop: disable CodeReuse/ActiveRecord
  def by_visibility_level(items)
    params[:visibility_level].present? ? items.where(visibility_level: params[:visibility_level]) : items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_tags(items)
    params[:tag].present? ? items.tagged_with(params[:tag]) : items
  end

  def by_search(items)
    params[:search] ||= params[:name]
    params[:search].present? ? items.search(params[:search]) : items
  end

  def by_deleted_status(items)
    params[:without_deleted].present? ? items.without_deleted : items
  end

  def sort(items)
    params[:sort].present? ? items.sort_by_attribute(params[:sort]) : items.order_id_desc
  end

  def by_archived(projects)
    if params[:non_archived]
      projects.non_archived
    elsif params.key?(:archived)
      if params[:archived] == 'only'
        projects.archived
      elsif Gitlab::Utils.to_boolean(params[:archived])
        projects
      else
        projects.non_archived
      end
    else
      projects
    end
  end

  def finder_params
    return {} unless min_access_level?

    { min_access_level: params[:min_access_level] }
  end
end
