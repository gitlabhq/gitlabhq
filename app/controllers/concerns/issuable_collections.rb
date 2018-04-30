module IssuableCollections
  extend ActiveSupport::Concern
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
    @issuable_meta_data = issuable_meta_data(@issuables, collection_type)
    @total_pages        = issuable_page_count
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def pagination_disabled?
    false
  end

  def issuables_collection
    finder.execute.preload(preload_for_collection)
  end

  def redirect_out_of_range(total_pages)
    return false if total_pages.nil? || total_pages.zero?

    out_of_range = @issuables.current_page > total_pages # rubocop:disable Gitlab/ModuleWithInstanceVariables

    if out_of_range
      redirect_to(url_for(params.merge(page: total_pages, only_path: true)))
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

  def issuable_finder_for(finder_class)
    finder_class.new(current_user, filter_params)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def filter_params
    set_sort_order_from_cookie
    set_default_state

    # Skip irrelevant Rails routing params
    @filter_params = params.dup.except(:controller, :action, :namespace_id)
    @filter_params[:sort] ||= default_sort_order

    @sort = @filter_params[:sort]

    if @project
      @filter_params[:project_id] = @project.id
    elsif @group
      @filter_params[:group_id] = @group.id
      @filter_params[:include_subgroups] = true
    else
      # TODO: this filter ignore issues/mr created in public or
      # internal repos where you are not a member. Enable this filter
      # or improve current implementation to filter only issues you
      # created or assigned or mentioned
      # @filter_params[:authorized_only] = true
    end

    @filter_params.permit(finder_type.valid_params)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def set_default_state
    params[:state] = 'opened' if params[:state].blank?
  end

  def set_sort_order_from_cookie
    key = 'issuable_sort'

    cookies[key] = params[:sort] if params[:sort].present?
    cookies[key] = update_cookie_value(cookies[key])
    params[:sort] = cookies[key]
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
    when 'created_asc'        then sort_value_created_date
    when 'created_desc'       then sort_value_created_date
    when 'due_date_asc'       then sort_value_due_date
    when 'due_date_desc'      then sort_value_due_date
    when 'milestone_due_asc'  then sort_value_milestone
    when 'milestone_due_desc' then sort_value_milestone
    when 'downvotes_asc'      then sort_value_popularity
    when 'downvotes_desc'     then sort_value_popularity
    when 'weight_asc'         then sort_value_weight
    when 'weight_desc'        then sort_value_weight
    else value
    end
  end

  def finder
    strong_memoize(:finder) do
      issuable_finder_for(finder_type)
    end
  end

  def collection_type
    @collection_type ||= case finder
                         when IssuesFinder
                           'Issue'
                         when MergeRequestsFinder
                           'MergeRequest'
                         end
  end

  def preload_for_collection
    @preload_for_collection ||= case collection_type
                                when 'Issue'
                                  [:project, :author, :assignees, :labels, :milestone, project: :namespace]
                                when 'MergeRequest'
                                  [
                                    :target_project, :author, :assignee, :labels, :milestone,
                                    source_project: :route, head_pipeline: :project, target_project: :namespace, latest_merge_request_diff: :merge_request_diff_commits
                                  ]
                                end
  end
end
