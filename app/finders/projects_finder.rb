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
#     tag: string[] - deprecated, use 'topic' instead
#     topic: string[]
#     topic_id: int
#     personal: boolean
#     search: string
#     search_namespaces: boolean
#     minimum_search_length: int
#     non_archived: boolean
#     archived: 'only' or boolean
#     min_access_level: integer
#     last_activity_after: datetime
#     last_activity_before: datetime
#     repository_storage: string
#     not_aimed_for_deletion: boolean
#     full_paths: string[]
#     organization: Scope the groups to the Organizations::Organization
#     language: int
#     language_name: string
#
class ProjectsFinder < UnionFinder
  include CustomAttributesFilter
  include UpdatedAtFilter
  include Projects::SearchFilter

  attr_accessor :params
  attr_reader :current_user, :project_ids_relation

  def initialize(params: {}, current_user: nil, project_ids_relation: nil)
    @params = params
    @current_user = current_user
    @project_ids_relation = project_ids_relation

    @params[:topic] ||= @params.delete(:tag) if @params[:tag].present?
  end

  def execute
    user = params.delete(:user)
    collection =
      if user
        PersonalProjectsFinder.new(user, finder_params).execute(current_user) # rubocop: disable CodeReuse/Finder
      else
        init_collection
      end

    if Feature.enabled?(:hide_projects_of_banned_users)
      collection = without_created_and_owned_by_banned_user(collection)
    end

    use_cte = params.delete(:use_cte)
    collection = Project.wrap_with_cte(collection) if use_cte
    collection = filter_projects(collection)

    sort(collection).allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/427628")
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
    collection = by_deleted_status(collection)
    collection = by_ids(collection)
    collection = by_full_paths(collection)
    collection = by_personal(collection)
    collection = by_starred(collection)
    collection = by_trending(collection)
    collection = by_visibility_level(collection)
    collection = by_topics(collection)
    collection = by_topic_id(collection)
    collection = by_search(collection)
    collection = by_archived(collection)
    collection = by_custom_attributes(collection)
    collection = by_not_aimed_for_deletion(collection)
    collection = by_last_activity_after(collection)
    collection = by_last_activity_before(collection)
    collection = by_language(collection)
    collection = by_feature_availability(collection)
    collection = by_updated_at(collection)
    collection = by_organization(collection)
    by_repository_storage(collection)
  end

  def collection_with_user
    if owned_projects?
      current_user.owned_projects
    elsif min_access_level?
      current_user.authorized_projects(params[:min_access_level])
    elsif private_only? || impossible_visibility_level?
      current_user.authorized_projects
    else
      Project.public_or_visible_to_user(current_user)
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

  # This is an optimization - surprisingly PostgreSQL does not optimize
  # for this.
  #
  # If the default visibility level and desired visibility level filter cancels
  # each other out, don't use the SQL clause for visibility level in
  # `Project.public_or_visible_to_user`. In fact, this then becomes equivalent
  # to just authorized projects for the user.
  #
  # E.g.
  # (EXISTS(<authorized_projects>) OR projects.visibility_level IN (10,20))
  #   AND "projects"."visibility_level" = 0
  #
  # is essentially
  # EXISTS(<authorized_projects>) AND "projects"."visibility_level" = 0
  #
  # See https://gitlab.com/gitlab-org/gitlab/issues/37007
  def impossible_visibility_level?
    return unless params[:visibility_level].present?

    public_visibility_levels = Gitlab::VisibilityLevel.levels_for_user(current_user)

    public_visibility_levels.exclude?(params[:visibility_level].to_i)
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

  def by_deleted_status(items)
    return items.without_deleted unless current_user&.can?(:admin_all_resources)

    params[:include_pending_delete].present? ? items : items.without_deleted
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_ids(items)
    items = items.where(id: project_ids_relation) if project_ids_relation
    items = items.where('projects.id > ?', params[:id_after]) if params[:id_after]
    items = items.where('projects.id < ?', params[:id_before]) if params[:id_before]
    items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_full_paths(items)
    params[:full_paths].present? ? items.where_full_path_in(params[:full_paths], preload_routes: false) : items
  end

  def union(items)
    find_union(items, Project).with_route
  end

  def by_personal(items)
    params[:personal].present? && current_user ? items.personal(current_user) : items
  end

  def by_starred(items)
    params[:starred].present? && current_user ? items.starred_by(current_user) : items
  end

  def by_trending(items)
    params[:trending].present? ? items.trending : items
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_visibility_level(items)
    params[:visibility_level].present? ? items.where(visibility_level: params[:visibility_level]) : items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_topics(items)
    return items unless params[:topic].present?

    topics = params[:topic].instance_of?(String) ? params[:topic].split(',') : params[:topic]
    topics.map(&:strip).uniq.reject(&:empty?).each do |topic|
      items = items.with_topic_by_name(topic)
    end

    items
  end

  def by_topic_id(items)
    return items unless params[:topic_id].present?

    topic = Projects::Topic.find_by(id: params[:topic_id]) # rubocop: disable CodeReuse/ActiveRecord
    return Project.none unless topic

    items.with_topic(topic)
  end

  def by_not_aimed_for_deletion(items)
    params[:not_aimed_for_deletion].present? ? items.not_aimed_for_deletion : items
  end

  def by_last_activity_after(items)
    if params[:last_activity_after].present?
      items.where("last_activity_at > ?", params[:last_activity_after]) # rubocop: disable CodeReuse/ActiveRecord
    else
      items
    end
  end

  def by_last_activity_before(items)
    if params[:last_activity_before].present?
      items.where("last_activity_at < ?", params[:last_activity_before]) # rubocop: disable CodeReuse/ActiveRecord
    else
      items
    end
  end

  def by_repository_storage(items)
    if params[:repository_storage].present?
      items.where(repository_storage: params[:repository_storage]) # rubocop: disable CodeReuse/ActiveRecord
    else
      items
    end
  end

  def by_language(items)
    return items.with_programming_language_id(params[:language]) if params[:language].present?
    return items.with_programming_language(params[:language_name]) if params[:language_name].present?

    items
  end

  def sort(items)
    return items.projects_order_id_desc unless params[:sort]

    return items.sorted_by_similarity_desc(params[:search]) if params[:sort] == 'similarity' && params[:search].present?

    items.sort_by_attribute(params[:sort])
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

  def by_feature_availability(items)
    items = items.with_issues_available_for_user(current_user) if params[:with_issues_enabled]
    items = items.with_merge_requests_available_for_user(current_user) if params[:with_merge_requests_enabled]
    items
  end

  def by_organization(items)
    organization = params[:organization]
    return items unless organization

    items.in_organization(organization)
  end

  def finder_params
    return {} unless min_access_level?

    { min_access_level: params[:min_access_level] }
  end

  def without_created_and_owned_by_banned_user(projects)
    return projects if current_user&.can?(:admin_all_resources)

    projects.without_created_and_owned_by_banned_user
  end
end

ProjectsFinder.prepend_mod_with('ProjectsFinder')
