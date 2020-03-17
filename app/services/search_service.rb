# frozen_string_literal: true

class SearchService
  include Gitlab::Allowable

  REDACTABLE_RESULTS = [
    ActiveRecord::Relation,
    Gitlab::Search::FoundBlob
  ].freeze

  SEARCH_TERM_LIMIT = 64
  SEARCH_CHAR_LIMIT = 4096

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params.dup
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def project
    return @project if defined?(@project)

    @project =
      if params[:project_id].present?
        the_project = Project.find_by(id: params[:project_id])
        can?(current_user, :read_project, the_project) ? the_project : nil
      else
        nil
      end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def group
    return @group if defined?(@group)

    @group =
      if params[:group_id].present?
        the_group = Group.find_by(id: params[:group_id])
        can?(current_user, :read_group, the_group) ? the_group : nil
      else
        nil
      end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def show_snippets?
    return @show_snippets if defined?(@show_snippets)

    @show_snippets = params[:snippets] == 'true'
  end

  def valid_query_length?
    params[:search].length <= SEARCH_CHAR_LIMIT
  end

  def valid_terms_count?
    params[:search].split.count { |word| word.length >= 3 } <= SEARCH_TERM_LIMIT
  end

  delegate :scope, to: :search_service

  def search_results
    @search_results ||= search_service.execute
  end

  def search_objects
    @search_objects ||= redact_unauthorized_results(search_results.objects(scope, params[:page]))
  end

  def redactable_results
    REDACTABLE_RESULTS
  end

  private

  def visible_result?(object)
    return true unless object.respond_to?(:to_ability_name) && DeclarativePolicy.has_policy?(object)

    Ability.allowed?(current_user, :"read_#{object.to_ability_name}", object)
  end

  def redact_unauthorized_results(results)
    return results unless redactable_results.any? { |redactable| results.is_a?(redactable) }

    permitted_results = results.select do |object|
      visible_result?(object)
    end

    filtered_results = (results - permitted_results).each_with_object({}) do |object, memo|
      memo[object.id] = { ability: :"read_#{object.to_ability_name}", id: object.id, class_name: object.class.name }
    end

    log_redacted_search_results(filtered_results.values) if filtered_results.any?

    return results.id_not_in(filtered_results.keys) if results.is_a?(ActiveRecord::Relation)

    Kaminari.paginate_array(
      permitted_results,
      total_count: results.total_count,
      limit: results.limit_value,
      offset: results.offset_value
    )
  end

  def log_redacted_search_results(filtered_results)
    logger.error(message: "redacted_search_results", filtered: filtered_results, current_user_id: current_user&.id, query: params[:search])
  end

  def logger
    @logger ||= ::Gitlab::RedactedSearchResultsLogger.build
  end

  def search_service
    @search_service ||=
      if project
        Search::ProjectService.new(project, current_user, params)
      elsif show_snippets?
        Search::SnippetService.new(current_user, params)
      elsif group
        Search::GroupService.new(current_user, group, params)
      else
        Search::GlobalService.new(current_user, params)
      end
  end

  attr_reader :current_user, :params
end

SearchService.prepend_if_ee('EE::SearchService')
