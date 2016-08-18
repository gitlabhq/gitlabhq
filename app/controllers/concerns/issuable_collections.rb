module IssuableCollections
  extend ActiveSupport::Concern
  include SortingHelper

  included do
    helper_method :issues_finder
    helper_method :merge_requests_finder
  end

  private

  def issues_collection
    issues_finder.execute
  end

  def merge_requests_collection
    merge_requests_finder.execute
  end

  def issues_finder
    @issues_finder ||= issuable_finder_for(IssuesFinder)
  end

  def merge_requests_finder
    @merge_requests_finder ||= issuable_finder_for(MergeRequestsFinder)
  end

  def issuable_finder_for(finder_class)
    finder_class.new(current_user, filter_params)
  end

  def filter_params
    set_sort_order_from_cookie
    set_default_scope
    set_default_state

    @filter_params = params.dup
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

    @filter_params
  end

  def set_default_scope
    params[:scope] = 'all' if params[:scope].blank?
  end

  def set_default_state
    params[:state] = 'opened' if params[:state].blank?
  end

  def set_sort_order_from_cookie
    key = 'issuable_sort'

    cookies[key] = params[:sort] if params[:sort].present?
    params[:sort] = cookies[key]
  end

  def default_sort_order
    case params[:state]
    when 'opened', 'all' then sort_value_recently_created
    when 'merged', 'closed' then sort_value_recently_updated
    else sort_value_recently_created
    end
  end
end
