# frozen_string_literal: true

class SearchController < ApplicationController
  include ControllerWithCrossProjectAccessCheck
  include SearchHelper
  include ProductAnalyticsTracking
  include Gitlab::InternalEventsTracking
  include SearchRateLimitable

  RESCUE_FROM_TIMEOUT_ACTIONS = [:count, :show, :autocomplete, :aggregations].freeze
  CODE_SEARCH_LITERALS = %w[blob: extension: path: filename:].freeze

  track_event :show,
    name: 'i_search_total',
    label: 'redis_hll_counters.search.search_total_unique_counts_monthly',
    action: 'executed',
    destinations: [:redis_hll, :snowplow]

  track_event :autocomplete,
    name: 'i_search_total',
    label: 'redis_hll_counters.search.search_total_unique_counts_monthly',
    action: 'autocomplete',
    destinations: [:redis_hll, :snowplow]

  def self.search_rate_limited_endpoints
    %i[show count autocomplete]
  end

  around_action :allow_gitaly_ref_name_caching

  skip_before_action :authenticate_user!, unless: :authenticate?

  before_action :check_scope_global_search_enabled, except: :opensearch

  requires_cross_project_access if: -> do
    search_term_present = params[:search].present? || params[:term].present?
    search_term_present && !params[:project_id].present?
  end
  before_action :check_search_rate_limit!, only: search_rate_limited_endpoints

  before_action only: :show do
    update_scope_for_code_search
  end

  before_action only: :show do
    push_frontend_feature_flag(:work_item_scope_frontend, current_user)
  end

  rescue_from ActiveRecord::QueryCanceled, with: :render_timeout

  layout 'search'

  feature_category :global_search
  urgency :low

  def show
    @project = search_service.project
    @group = search_service.group
    @search_service_presenter = Gitlab::View::Presenter::Factory.new(
      search_service,
      current_user: current_user
    ).fabricate!

    return unless search_term_valid? && search_type_valid?

    return if check_single_commit_result?

    @search_term = params[:search]
    @sort = params[:sort] || default_sort

    @search_level = @search_service_presenter.level
    @search_type = search_type
    @scope = @search_service_presenter.scope

    # separate following lines to method that is conditionally triggered when not zoekt multi-result search
    haml_search_results unless multi_match?(scope: @scope, search_type: search_type)
  end

  def count
    params.require([:search, :scope])

    scope = search_service.scope

    @search_level = search_service.level
    @search_type = search_type

    count = 0
    @global_search_duration_s = Benchmark.realtime do
      count = if @search_type == 'basic'
                ApplicationRecord.with_fast_read_statement_timeout do
                  search_service.search_results.formatted_count(scope)
                end
              else
                search_service.search_results.formatted_count(scope)
              end

      # Users switching tabs will keep fetching the same tab counts so it's a
      # good idea to cache in their browser just for a short time. They can still
      # clear cache if they are seeing an incorrect count but inaccurate count is
      # not such a bad thing.
      expires_in 1.minute

      render json: { count: count }
    end
  end

  def settings
    return render(json: []) unless current_user

    project_id, group_id = params.permit(:project_id, :group_id).values_at(:project_id, :group_id)

    if project_id
      render json: settings_for_project(project_id)
    elsif group_id
      render json: settings_for_group(group_id)
    else
      head :bad_request
    end
  end

  def autocomplete
    term = params.require(:term)

    @project = search_service.project
    @ref = params[:project_ref] if params[:project_ref].present?
    @filter = params[:filter]
    @scope = params[:scope]

    # Cache the response on the frontend
    expires_in 1.minute

    render json: Gitlab::Json.dump(search_autocomplete_opts(term, filter: @filter, scope: @scope))
  end

  def opensearch; end

  private

  def authenticate?
    return false if action_name == 'opensearch'
    return true if public_visibility_restricted?
    return true if search_service.global_search? && ::Feature.enabled?(:block_anonymous_global_searches, type: :ops)
    return true if ::Feature.disabled?(:allow_anonymous_searches, type: :ops)

    false
  end

  def multi_match?(search_type:, scope:) # rubocop: disable Lint/UnusedMethodArgument -- This is being overridden in EE
    false
  end

  def haml_search_results
    @global_search_duration_s = Benchmark.realtime do
      @search_results = @search_service_presenter.search_results
      @search_objects = @search_service_presenter.search_objects
      @search_highlight = @search_service_presenter.search_highlight
    end

    return if @search_results.respond_to?(:failed?) && @search_results.failed?(@scope)

    Gitlab::Metrics::GlobalSearchSlis.record_apdex(
      elapsed: @global_search_duration_s,
      search_type: @search_type,
      search_level: @search_level,
      search_scope: @scope
    )

    increment_search_counters
  ensure
    if @search_type
      # If we raise an error somewhere in the @global_search_duration_s benchmark block, we will end up here
      # with a 200 status code, but an empty @global_search_duration_s.
      Gitlab::Metrics::GlobalSearchSlis.record_error_rate(
        error: @global_search_duration_s.nil? || (status < 200 || status >= 400),
        search_type: @search_type,
        search_level: @search_level,
        search_scope: @scope
      )
    end
  end

  def update_scope_for_code_search
    return if params[:scope] == 'blobs'
    return unless params[:search].present?

    return unless CODE_SEARCH_LITERALS.any? { |literal| literal.in? params[:search] }

    redirect_to search_path(safe_params.except(:controller, :action).merge(scope: 'blobs'))
  end

  # overridden in EE
  def default_sort
    'created_desc'
  end

  def search_term_valid?
    return false if params[:search].blank?

    unless search_service.valid_query_length?
      flash[:alert] = t('errors.messages.search_chars_too_long', count: Gitlab::Search::Params::SEARCH_CHAR_LIMIT)
      return false
    end

    unless search_service.valid_terms_count?
      flash[:alert] = t('errors.messages.search_terms_too_long', count: Gitlab::Search::Params::SEARCH_TERM_LIMIT)
      return false
    end

    true
  end

  def search_type_valid?
    search_type_errors = search_service.search_type_errors

    if search_type_errors
      flash[:alert] = search_type_errors
      return false
    end

    true
  end

  def check_single_commit_result?
    return false if params[:force_search_results]
    return false unless @project.present?
    return false unless Ability.allowed?(current_user, :read_code, @project)

    query = params[:search].strip.downcase
    return false unless Commit.valid_hash?(query)

    commit = @project.commit_by(oid: query)
    return false unless commit.present?

    link = search_path(safe_params.merge(force_search_results: true))
    flash[:notice] = ERB::Util.html_escape(
      _(
        "You have been redirected to the only result; " \
          "see the %{a_start}search results%{a_end} instead."
      )
    ) % {
      a_start: "<a href=\"#{link}\"><u>".html_safe, a_end: '</u></a>'.html_safe
    }
    redirect_to project_commit_path(@project, commit)

    true
  end

  def increment_search_counters
    track_internal_event('perform_search', user: current_user)

    return if params[:nav_source] != 'navbar'

    track_internal_event('perform_navbar_search', user: current_user)
  end

  def append_info_to_payload(payload)
    super

    # Merging to :metadata will ensure these are logged as top level keys
    payload[:metadata] ||= {}
    payload[:metadata].merge!(payload_metadata)

    return unless search_service.abuse_detected?

    payload[:metadata]['abuse.confidence'] = Gitlab::Abuse.confidence(:certain)
    payload[:metadata]['abuse.messages'] = search_service.abuse_messages
  end

  def payload_metadata
    {}.tap do |metadata|
      metadata['meta.search.group_id'] = params[:group_id]
      metadata['meta.search.project_id'] = params[:project_id]
      metadata['meta.search.scope'] = params[:scope] || @scope
      metadata['meta.search.page'] = params[:page] || '1'
      metadata['meta.search.filters.confidential'] = filter_params[:confidential]
      metadata['meta.search.filters.state'] = filter_params[:state]
      metadata['meta.search.force_search_results'] = params[:force_search_results]
      metadata['meta.search.project_ids'] = params[:project_ids]
      metadata['meta.search.filters.language'] = filter_params[:language]
      metadata['meta.search.type'] = @search_type if @search_type.present?
      metadata['meta.search.level'] = @search_level if @search_level.present?
      metadata[:global_search_duration_s] = @global_search_duration_s if @global_search_duration_s.present?
    end
  end

  def check_scope_global_search_enabled
    return unless search_service.global_search?

    return if search_service.global_search_enabled_for_scope?

    redirect_to search_path, alert: _('Global Search is disabled for this scope')
  end

  def render_timeout(exception)
    raise exception unless action_name.to_sym.in?(RESCUE_FROM_TIMEOUT_ACTIONS)

    log_exception(exception)

    @timeout = true

    case action_name.to_sym
    when :count
      render json: {}, status: :request_timeout
    when :autocomplete, :aggregations
      render json: [], status: :request_timeout
    else
      render status: :request_timeout
    end
  end

  def tracking_namespace_source
    search_service.project&.namespace || search_service.group
  end

  def tracking_project_source
    search_service.project
  end

  def search_type
    search_service.search_type
  end

  def filter_params
    params.permit(:confidential, :state, language: [])
  end

  def settings_for_project(project_id)
    project = Project.find_by(id: project_id) # rubocop: disable CodeReuse/ActiveRecord -- Using `find` would raise 404s
    return [] unless project && current_user.can?(:admin_project, project)

    Search::ProjectSettings.new(project).all
  end

  def settings_for_group(group_id)
    group = Group.find_by(id: group_id) # rubocop: disable CodeReuse/ActiveRecord -- Using `find` would raise 404s
    return [] unless group && current_user.can?(:admin_group, group)

    Search::GroupSettings.new(group).all
  end
end

SearchController.prepend_mod_with('SearchController')
