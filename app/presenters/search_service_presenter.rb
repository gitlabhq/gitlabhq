# frozen_string_literal: true

class SearchServicePresenter < Gitlab::View::Presenter::Delegated
  include RendersCommits
  include RendersProjectsList

  presents ::SearchService, as: :search_service

  SCOPE_PRELOAD_METHOD = {
    projects: :with_web_entity_associations,
    issues: :with_web_entity_associations,
    merge_requests: :with_web_entity_associations,
    epics: :with_web_entity_associations,
    notes: :with_web_entity_associations,
    milestones: :with_web_entity_associations,
    commits: :with_web_entity_associations,
    blobs: :with_web_entity_associations
  }.freeze

  SORT_ENABLED_SCOPES = %w[issues merge_requests epics].freeze

  delegator_override :search_objects
  def search_objects
    @search_objects ||= begin
      objects = search_service.search_objects(SCOPE_PRELOAD_METHOD[scope.to_sym])

      case scope
      when 'users'
        objects.respond_to?(:eager_load) ? objects.eager_load(:status) : objects # rubocop:disable CodeReuse/ActiveRecord
      when 'commits'
        prepare_commits_for_rendering(objects)
      when 'projects'
        prepare_projects_for_rendering(objects)
      else
        objects
      end
    end
  end

  def show_sort_dropdown?
    SORT_ENABLED_SCOPES.include?(scope)
  end

  def show_results_status?
    !without_count? || show_snippets? || show_sort_dropdown?
  end

  def without_count?
    search_objects.is_a?(Kaminari::PaginatableWithoutCount)
  end

  def advanced_search_enabled?
    false
  end

  def zoekt_enabled?
    false
  end
end

SearchServicePresenter.prepend_mod_with('SearchServicePresenter')
