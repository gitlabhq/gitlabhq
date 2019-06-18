# frozen_string_literal: true

module IssuableCollections
  extend ActiveSupport::Concern
  include CookiesHelper
  include SortingHelper
  include Gitlab::IssuableMetadata
  include Gitlab::Utils::StrongMemoize

  included do
    helper_method :finder
  end

  private

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def set_issuables_index
    @issuables = issuables_collection

    set_pagination
    return if redirect_out_of_range(@total_pages)

    if params[:label_name].present? && @project
      labels_params = { project_id: @project.id, title: params[:label_name] }
      @labels = LabelsFinder.new(current_user, labels_params).execute
    end

    @users = []
    if params[:assignee_id].present?
      assignee = User.find_by_id(params[:assignee_id])
      @users.push(assignee) if assignee
    end

    if params[:author_id].present?
      author = User.find_by_id(params[:author_id])
      @users.push(author) if author
    end
  end

  def set_pagination
    return if pagination_disabled?

    @issuables          = @issuables.page(params[:page])
    @issuables          = per_page_for_relative_position if params[:sort] == 'relative_position'
    @issuable_meta_data = issuable_meta_data(@issuables, collection_type)
    @total_pages        = issuable_page_count
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def pagination_disabled?
    false
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def issuables_collection
    finder.execute.preload(preload_for_collection)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def redirect_out_of_range(total_pages)
    return false if total_pages.nil? || total_pages.zero?

    out_of_range = @issuables.current_page > total_pages # rubocop:disable Gitlab/ModuleWithInstanceVariables

    if out_of_range
      redirect_to(url_for(safe_params.merge(page: total_pages, only_path: true)))
    end

    out_of_range
  end

  def issuable_page_count
    page_count_for_relation(@issuables, finder.row_count) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def page_count_for_relation(relation, row_count)
    limit = relation.limit_value.to_f

    return 1 if limit.zero?

    (row_count.to_f / limit).ceil
  end

  # manual / relative_position sorting allows for 100 items on the page
  def per_page_for_relative_position
    @issuables.per(100) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def issuable_finder_for(finder_class)
    finder_class.new(current_user, finder_options)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def finder_options
    params[:state] = default_state if params[:state].blank?

    options = {
      scope: params[:scope],
      state: params[:state],
      confidential: Gitlab::Utils.to_boolean(params[:confidential]),
      sort: set_sort_order
    }

    # Used by view to highlight active option
    @sort = options[:sort]

    # When a user looks for an exact iid, we do not filter by search but only by iid
    if params[:search] =~ /^#(?<iid>\d+)\z/
      options[:iids] = Regexp.last_match[:iid]
      params[:search] = nil
    end

    if @project
      options[:project_id] = @project.id
      options[:attempt_project_search_optimizations] = true
    elsif @group
      options[:group_id] = @group.id
      options[:include_subgroups] = true
      options[:attempt_group_search_optimizations] = true
    end

    params.permit(finder_type.valid_params).merge(options)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def default_state
    'opened'
  end

  def set_sort_order
    set_sort_order_from_user_preference || set_sort_order_from_cookie || default_sort_order
  end

  def set_sort_order_from_user_preference
    return unless current_user
    return unless issuable_sorting_field

    user_preference = current_user.user_preference

    sort_param = params[:sort]
    sort_param ||= user_preference[issuable_sorting_field]

    return sort_param if Gitlab::Database.read_only?

    if user_preference[issuable_sorting_field] != sort_param
      user_preference.update(issuable_sorting_field => sort_param)
    end

    sort_param
  end

  # Implement issuable_sorting_field method on controllers
  # to choose which column to store the sorting parameter.
  def issuable_sorting_field
    nil
  end

  def set_sort_order_from_cookie
    sort_param = params[:sort] if params[:sort].present?
    # fallback to legacy cookie value for backward compatibility
    sort_param ||= cookies['issuable_sort']
    sort_param ||= cookies[remember_sorting_key]

    sort_value = update_cookie_value(sort_param)
    set_secure_cookie(remember_sorting_key, sort_value)
    sort_value
  end

  def remember_sorting_key
    @remember_sorting_key ||= "#{collection_type.downcase}_sort"
  end

  def default_sort_order
    case params[:state]
    when 'opened', 'all'    then sort_value_created_date
    when 'merged', 'closed' then sort_value_recently_updated
    else sort_value_created_date
    end
  end

  # Update old values to the actual ones.
  def update_cookie_value(value)
    case value
    when 'id_asc'             then sort_value_oldest_created
    when 'id_desc'            then sort_value_recently_created
    when 'downvotes_asc'      then sort_value_popularity
    when 'downvotes_desc'     then sort_value_popularity
    else value
    end
  end

  def finder
    @finder ||= issuable_finder_for(finder_type)
  end

  def collection_type
    @collection_type ||= case finder_type.name
                         when 'IssuesFinder'
                           'Issue'
                         when 'MergeRequestsFinder'
                           'MergeRequest'
                         end
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def preload_for_collection
    common_attributes = [:author, :assignees, :labels, :milestone]
    @preload_for_collection ||= case collection_type
                                when 'Issue'
                                  common_attributes + [:project, project: :namespace]
                                when 'MergeRequest'
                                  common_attributes + [:target_project, source_project: :route, head_pipeline: :project, target_project: :namespace, latest_merge_request_diff: :merge_request_diff_commits]
                                end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
