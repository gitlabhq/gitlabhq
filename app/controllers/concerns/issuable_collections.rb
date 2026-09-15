# frozen_string_literal: true

module IssuableCollections
  extend ActiveSupport::Concern
  include PaginatedCollection
  include SearchRateLimitable
  include SortingHelper
  include SortingPreference
  include Gitlab::Utils::StrongMemoize

  included do
    helper_method :finder
  end

  private

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def set_issuables_index
    @issuables = issuables_collection
    set_pagination

    nil if redirect_out_of_range(@issuables, @total_pages)
  end

  def set_pagination
    pagination_result = paginate_for_collection(@issuables, row_count: finder.row_count)

    @issuables = pagination_result[:collection]
    @total_pages = pagination_result[:total_pages]
    @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @issuables).data
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # rubocop: disable CodeReuse/ActiveRecord
  def issuables_collection
    finder.execute.preload(preload_for_collection)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def issuable_finder_for(finder_class)
    finder_class.new(current_user, finder_options)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def finder_options
    normalize_filter_params!

    filter_params = issuable_filter_params

    options = {
      scope: filter_params[:scope],
      state: filter_params[:state],
      confidential: Gitlab::Utils.to_boolean(filter_params[:confidential]),
      sort: set_sort_order
    }
    options[:iids] = search_iid if search_iid

    # Used by view to highlight active option
    @sort = options[:sort]

    if @project
      options[:project_id] = @project.id
      options[:attempt_project_search_optimizations] = true
    elsif @group
      options[:group_id] = @group.id
      options[:include_subgroups] = true
      options[:attempt_group_search_optimizations] = true
    end

    filter_params.merge(options)
  end
  strong_memoize_attr :finder_options
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # Writes land on `params` itself rather than a permitted copy, because shared/issuable/_nav
  # reads params[:state] for the active tab and the search box re-reads params[:search].
  # Must run before issuable_filter_params so the permit captures the normalized values.
  def normalize_filter_params!
    # rubocop:disable Rails/StrongParams -- deliberate in-place normalization, see above
    params[:state] = default_state if state_param.blank?
    params[:search] = nil if search_iid
    # rubocop:enable Rails/StrongParams
  end

  # An exact iid search filters by iid instead of search. Memoized because
  # normalize_filter_params! clears params[:search] once it has matched.
  def search_iid
    match = params.permit(:search)[:search]&.match(/^#(?<iid>\d+)\z/)
    match && match[:iid]
  end
  strong_memoize_attr :search_iid

  # :scope, :state and :confidential are consumed by finder_options but are not part
  # of finder_type.valid_params, so they must be permitted explicitly.
  def issuable_filter_params
    params.permit(:scope, :state, :confidential, *finder_type.valid_params)
  end

  def state_param
    params.permit(:state)[:state]
  end

  def default_state
    'opened'
  end

  def legacy_sort_cookie_name
    'issuable_sort'
  end

  def default_sort_order
    if %w[merged closed].include?(state_param)
      sort_value_recently_updated
    else
      sort_value_created_date
    end
  end

  def finder
    @finder ||= issuable_finder_for(finder_type)
  end

  def collection_type
    @collection_type ||= if finder_type <= IssuesFinder
                           'Issue'
                         elsif finder_type <= MergeRequestsFinder
                           'MergeRequest'
                         end
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def preload_for_collection
    common_attributes = [:author, :assignees, :labels, :milestone]
    @preload_for_collection ||= case collection_type
                                when 'Issue'
                                  common_attributes + [
                                    :project, { project: :namespace }
                                  ]
                                when 'MergeRequest'
                                  common_attributes + [
                                    :target_project, :latest_merge_request_diff, :approvals,
                                    :approved_by_users, :reviewers,
                                    { source_project: :route, head_pipeline: :project, target_project: :namespace }
                                  ]
                                end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end

IssuableCollections.prepend_mod_with('IssuableCollections')
