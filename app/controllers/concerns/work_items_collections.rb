# frozen_string_literal: true

module WorkItemsCollections
  extend ActiveSupport::Concern
  include SearchRateLimitable
  include SortingHelper
  include SortingPreference
  include Gitlab::Utils::StrongMemoize
  include PaginatedCollection

  private

  def work_items_for_rss
    base_collection = finder
      .execute
      .preload_namespace_routables
      .preload_routables
      .preload_for_rss

    pagination_result = paginate_for_collection(base_collection, row_count: finder.row_count)

    pagination_result[:collection]
  end

  def work_items_for_calendar
    finder
      .execute
      .preload_namespace_routables
      .preload_routables
      .non_archived
      .with_due_date
      .limit(100)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables -- we need to use params in the finder
  def finder_options
    work_items_collection_params[:state] = (params.permit([:state])[:state].presence || default_state)

    options = {
      scope: params.permit([:scope])[:scope],
      state: work_items_collection_params[:state],
      confidential: Gitlab::Utils.to_boolean(work_items_collection_params[:confidential]),
      sort: set_sort_order
    }

    # Used by view to highlight active option
    @sort = options[:sort]

    # When a user looks for an exact iid, we do not filter by search but only by iid
    if work_items_collection_params[:search] =~ /^#(?<iid>\d+)\z/
      options[:iids] = Regexp.last_match[:iid]
      work_items_collection_params[:search] = nil
    end

    if @project
      options[:project_id] = @project.id
      options[:attempt_project_search_optimizations] = true
    elsif @group
      options[:group_id] = @group.id
      options[:include_descendants] = true
      options[:exclude_group_work_items] = true
      options[:attempt_group_search_optimizations] = true
    end

    work_items_collection_params.merge(options)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  strong_memoize_attr :finder_options

  def default_state
    'opened'
  end

  def default_sort_order
    if %w[merged closed].include?(work_items_collection_params[:state])
      sort_value_recently_updated
    else
      sort_value_created_date
    end
  end

  def finder
    @finder ||= WorkItems::WorkItemsFinder.new(current_user, finder_options)
  end

  def work_items_collection_params
    @work_items_collection_params ||= params.permit(WorkItems::WorkItemsFinder.valid_params)
  end
end
