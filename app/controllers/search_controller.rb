# frozen_string_literal: true

class SearchController < ApplicationController
  include ControllerWithCrossProjectAccessCheck
  include SearchHelper
  include RedisTracking

  track_redis_hll_event :show, name: 'i_search_total'

  around_action :allow_gitaly_ref_name_caching

  before_action :block_anonymous_global_searches, except: :opensearch
  skip_before_action :authenticate_user!
  requires_cross_project_access if: -> do
    search_term_present = params[:search].present? || params[:term].present?
    search_term_present && !params[:project_id].present?
  end

  rescue_from ActiveRecord::QueryCanceled, with: :render_timeout

  layout 'search'

  feature_category :global_search

  def show
    @project = search_service.project
    @group = search_service.group

    return if params[:search].blank?

    return unless search_term_valid?

    return if check_single_commit_result?

    @search_term = params[:search]
    @sort = params[:sort] || default_sort

    @search_service = Gitlab::View::Presenter::Factory.new(search_service, current_user: current_user).fabricate!
    @scope = @search_service.scope
    @show_snippets = @search_service.show_snippets?
    @search_results = @search_service.search_results
    @search_objects = @search_service.search_objects
    @search_highlight = @search_service.search_highlight

    increment_search_counters
  end

  def count
    params.require([:search, :scope])

    scope = search_service.scope

    count = 0
    ApplicationRecord.with_fast_read_statement_timeout do
      count = search_service.search_results.formatted_count(scope)
    end

    # Users switching tabs will keep fetching the same tab counts so it's a
    # good idea to cache in their browser just for a short time. They can still
    # clear cache if they are seeing an incorrect count but inaccurate count is
    # not such a bad thing.
    expires_in 1.minute

    render json: { count: count }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def autocomplete
    term = params[:term]

    if params[:project_id].present?
      @project = Project.find_by(id: params[:project_id])
      @project = nil unless can?(current_user, :read_project, @project)
    end

    @ref = params[:project_ref] if params[:project_ref].present?

    render json: search_autocomplete_opts(term).to_json
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def opensearch
  end

  private

  # overridden in EE
  def default_sort
    'created_desc'
  end

  def search_term_valid?
    unless search_service.valid_query_length?
      flash[:alert] = t('errors.messages.search_chars_too_long', count: SearchService::SEARCH_CHAR_LIMIT)
      return false
    end

    unless search_service.valid_terms_count?
      flash[:alert] = t('errors.messages.search_terms_too_long', count: SearchService::SEARCH_TERM_LIMIT)
      return false
    end

    true
  end

  def check_single_commit_result?
    return false if params[:force_search_results]
    return false unless @project.present?
    # download_code project policy grants user the read_commit ability
    return false unless Ability.allowed?(current_user, :download_code, @project)

    query = params[:search].strip.downcase
    return false unless Commit.valid_hash?(query)

    commit = @project.commit_by(oid: query)
    return false unless commit.present?

    link = search_path(safe_params.merge(force_search_results: true))
    flash[:notice] = html_escape(_("You have been redirected to the only result; see the %{a_start}search results%{a_end} instead.")) % { a_start: "<a href=\"#{link}\"><u>".html_safe, a_end: '</u></a>'.html_safe }
    redirect_to project_commit_path(@project, commit)

    true
  end

  def increment_search_counters
    Gitlab::UsageDataCounters::SearchCounter.count(:all_searches)

    return if params[:nav_source] != 'navbar'

    Gitlab::UsageDataCounters::SearchCounter.count(:navbar_searches)
  end

  def append_info_to_payload(payload)
    super

    # Merging to :metadata will ensure these are logged as top level keys
    payload[:metadata] ||= {}
    payload[:metadata]['meta.search.group_id'] = params[:group_id]
    payload[:metadata]['meta.search.project_id'] = params[:project_id]
    payload[:metadata]['meta.search.scope'] = params[:scope] || @scope
    payload[:metadata]['meta.search.filters.confidential'] = params[:confidential]
    payload[:metadata]['meta.search.filters.state'] = params[:state]
    payload[:metadata]['meta.search.force_search_results'] = params[:force_search_results]
  end

  def block_anonymous_global_searches
    return if params[:project_id].present? || params[:group_id].present?
    return if current_user
    return unless ::Feature.enabled?(:block_anonymous_global_searches)

    store_location_for(:user, request.fullpath)

    redirect_to new_user_session_path, alert: _('You must be logged in to search across all of GitLab')
  end

  def render_timeout(exception)
    raise exception unless action_name.to_sym == :show

    log_exception(exception)

    @timeout = true
    render status: :request_timeout
  end
end

SearchController.prepend_mod_with('SearchController')
