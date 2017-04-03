module IssuableCollections
  extend ActiveSupport::Concern
  include SortingHelper

  included do
    helper_method :issues_finder
    helper_method :merge_requests_finder
  end

  private

  def issuable_meta_data(issuable_collection, collection_type)
    # map has to be used here since using pluck or select will
    # throw an error when ordering issuables by priority which inserts
    # a new order into the collection.
    # We cannot use reorder to not mess up the paginated collection.
    issuable_ids = issuable_collection.map(&:id)
    issuable_note_count = Note.count_for_collection(issuable_ids, @collection_type)
    issuable_votes_count = AwardEmoji.votes_for_collection(issuable_ids, @collection_type)
    issuable_merge_requests_count =
      if collection_type == 'Issue'
        MergeRequestsClosingIssues.count_for_collection(issuable_ids)
      else
        []
      end

    issuable_ids.each_with_object({}) do |id, issuable_meta|
      downvotes = issuable_votes_count.find { |votes| votes.awardable_id == id && votes.downvote? }
      upvotes = issuable_votes_count.find { |votes| votes.awardable_id == id && votes.upvote? }
      notes = issuable_note_count.find { |notes| notes.noteable_id == id }
      merge_requests = issuable_merge_requests_count.find { |mr| mr.first == id }

      issuable_meta[id] = Issuable::IssuableMeta.new(
        upvotes.try(:count).to_i,
        downvotes.try(:count).to_i,
        notes.try(:count).to_i,
        merge_requests.try(:last).to_i
      )
    end
  end

  def issues_collection
    issues_finder.execute.preload(:project, :author, :assignee, :labels, :milestone, project: :namespace)
  end

  def merge_requests_collection
    merge_requests_finder.execute.preload(:source_project, :target_project, :author, :assignee, :labels, :milestone, :merge_request_diff, target_project: :namespace)
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

    # id_desc and id_asc are old values for these two.
    cookies[key] = sort_value_recently_created if cookies[key] == 'id_desc'
    cookies[key] = sort_value_oldest_created if cookies[key] == 'id_asc'

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
