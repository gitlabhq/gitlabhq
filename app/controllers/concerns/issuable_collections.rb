module IssuableCollections
  extend ActiveSupport::Concern
  include SortingHelper
  include Gitlab::IssuableMetadata

  included do
    helper_method :issues_finder
    helper_method :merge_requests_finder
  end

  private

  def set_issues_index
    @collection_type    = "Issue"
    @issues             = issues_collection
    @issues             = @issues.page(params[:page])
    @issuable_meta_data = issuable_meta_data(@issues, @collection_type)
    @total_pages        = issues_page_count(@issues)

    return if redirect_out_of_range(@issues, @total_pages)

    if params[:label_name].present?
      @labels = LabelsFinder.new(current_user, project_id: @project.id, title: params[:label_name]).execute
    end

    @users = []
  end

  def issues_collection
    issues_finder.execute.preload(:project, :author, :assignees, :labels, :milestone, project: :namespace)
  end

  def merge_requests_collection
    merge_requests_finder.execute.preload(
      :source_project,
      :target_project,
      :author,
      :assignee,
      :labels,
      :milestone,
      head_pipeline: :project,
      target_project: :namespace,
      merge_request_diff: :merge_request_diff_commits
    )
  end

  def issues_finder
    @issues_finder ||= issuable_finder_for(IssuesFinder)
  end

  def merge_requests_finder
    @merge_requests_finder ||= issuable_finder_for(MergeRequestsFinder)
  end

  def redirect_out_of_range(relation, total_pages)
    return false if total_pages.zero?

    out_of_range = relation.current_page > total_pages

    if out_of_range
      redirect_to(url_for(params.merge(page: total_pages, only_path: true)))
    end

    out_of_range
  end

  def issues_page_count(relation)
    page_count_for_relation(relation, issues_finder.row_count)
  end

  def merge_requests_page_count(relation)
    page_count_for_relation(relation, merge_requests_finder.row_count)
  end

  def page_count_for_relation(relation, row_count)
    limit = relation.limit_value.to_f

    return 1 if limit.zero?

    (row_count.to_f / limit).ceil
  end

  def issuable_finder_for(finder_class)
    finder_class.new(current_user, filter_params)
  end

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
    else
      # TODO: this filter ignore issues/mr created in public or
      # internal repos where you are not a member. Enable this filter
      # or improve current implementation to filter only issues you
      # created or assigned or mentioned
      # @filter_params[:authorized_only] = true
    end

    @filter_params.permit(IssuableFinder::VALID_PARAMS)
  end

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
end
