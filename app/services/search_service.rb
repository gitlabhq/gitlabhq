# frozen_string_literal: true

class SearchService
  include Gitlab::Allowable
  include Gitlab::Utils::StrongMemoize

  DEFAULT_PER_PAGE = Gitlab::SearchResults::DEFAULT_PER_PAGE
  MAX_PER_PAGE = 200

  attr_reader :params

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = Gitlab::Search::Params.new(params, detect_abuse: true)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def project
    return unless params[:project_id].present? && valid_request?

    the_project = Project.find_by(id: params[:project_id])
    can?(current_user, :read_project, the_project) ? the_project : nil
  end
  strong_memoize_attr :project
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def group
    return unless params[:group_id].present? && valid_request?

    the_group = Group.find_by(id: params[:group_id])
    can?(current_user, :read_group, the_group) ? the_group : nil
  end
  strong_memoize_attr :group
  # rubocop: enable CodeReuse/ActiveRecord

  def projects
    # overridden in EE
  end

  def search_type_errors
    # overridden in EE
  end

  def global_search?
    project.blank? && group.blank?
  end

  def search_type
    'basic'
  end

  def show_snippets?
    params[:snippets] == 'true'
  end
  strong_memoize_attr :show_snippets?

  delegate :scope, to: :search_service
  delegate :valid_terms_count?, :valid_query_length?, to: :params

  def search_results
    abuse_detected? ? ::Search::EmptySearchResults.new : search_service.execute
  end
  strong_memoize_attr :search_results

  def search_objects(preload_method = nil)
    @search_objects ||= redact_unauthorized_results(
      search_results.objects(scope, page: page, per_page: per_page, preload_method: preload_method)
    )
  end

  def search_highlight
    search_results.highlight_map(scope)
  end

  def search_aggregations
    search_results.aggregations(scope)
  end

  def abuse_detected?
    params.abusive?
  end
  strong_memoize_attr :abuse_detected?

  def abuse_messages
    return [] unless params.abusive?

    params.abuse_detection.errors.full_messages
  end

  def valid_request?
    params.valid?
  end
  strong_memoize_attr :valid_request?

  def level
    @level ||=
      if project
        'project'
      elsif group
        'group'
      else
        'global'
      end
  end

  def global_search_enabled_for_scope?
    return false if show_snippets? && !::Gitlab::CurrentSettings.global_search_snippet_titles_enabled?

    case params[:scope]
    when 'issues'
      ::Gitlab::CurrentSettings.global_search_issues_enabled?
    when 'merge_requests'
      ::Gitlab::CurrentSettings.global_search_merge_requests_enabled?
    when 'snippet_titles'
      ::Gitlab::CurrentSettings.global_search_snippet_titles_enabled?
    when 'users'
      ::Gitlab::CurrentSettings.global_search_users_enabled?
    else
      true
    end
  end

  private

  def page
    [1, params[:page].to_i].max
  end

  def per_page
    per_page_param = params[:per_page].to_i

    return DEFAULT_PER_PAGE unless per_page_param > 0

    [MAX_PER_PAGE, per_page_param].min
  end

  def visible_result?(object)
    return true unless object.respond_to?(:to_ability_name) && DeclarativePolicy.has_policy?(object)

    Ability.allowed?(current_user, :"read_#{object.to_ability_name}", object)
  end

  def redact_unauthorized_results(results_collection)
    redacted_results = results_collection.reject { |object| visible_result?(object) }

    if redacted_results.any?
      redacted_log = redacted_results.each_with_object({}) do |object, memo|
        memo[object.id] = { ability: :"read_#{object.to_ability_name}", id: object.id, class_name: object.class.name }
      end

      log_redacted_search_results(redacted_log.values)

      return results_collection.id_not_in(redacted_log.keys) if results_collection.is_a?(ActiveRecord::Relation)
    end

    return results_collection if results_collection.is_a?(ActiveRecord::Relation)

    permitted_results = results_collection - redacted_results

    Kaminari.paginate_array(
      permitted_results,
      total_count: results_collection.total_count,
      limit: results_collection.limit_value,
      offset: results_collection.offset_value
    )
  end

  def log_redacted_search_results(filtered_results)
    request_info = {
      class: self.class.name,
      message: 'redacted_search_results',
      filtered: filtered_results,
      current_user_id: current_user&.id,
      query: params[:search],
      "meta.search.type": search_type,
      "meta.search.level": level
    }

    logger.error(request_info)
  end

  def logger
    @logger ||= ::Gitlab::RedactedSearchResultsLogger.build
  end

  def search_service
    @search_service ||=
      if project
        Search::ProjectService.new(current_user, project, params)
      elsif show_snippets?
        Search::SnippetService.new(current_user, params)
      elsif group
        Search::GroupService.new(current_user, group, params)
      else
        Search::GlobalService.new(current_user, params)
      end
  end

  attr_reader :current_user
end

SearchService.prepend_mod_with('SearchService')
