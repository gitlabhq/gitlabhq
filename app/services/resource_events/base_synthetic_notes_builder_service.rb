# frozen_string_literal: true

# We store events about issuable label changes and weight changes in a separate
# table (not as other system notes), but we still want to display notes about
# label changes and weight changes as classic system notes in UI.  This service
# generates "synthetic" notes for label event changes.

module ResourceEvents
  class BaseSyntheticNotesBuilderService
    include Gitlab::Utils::StrongMemoize

    attr_reader :resource, :current_user, :params

    def initialize(resource, current_user, params = {})
      @resource = resource
      @current_user = current_user
      @params = params
    end

    def execute
      synthetic_notes
    end

    private

    def apply_common_filters(events)
      events = apply_pagination(events)
      apply_last_fetched_at(events)
    end

    def apply_pagination(events)
      return events if params[:paginated_notes].nil?
      return events.none if params[:paginated_notes][table_name].blank?

      events.id_in(params[:paginated_notes][table_name].flat_map(&:ids))
    end

    def apply_last_fetched_at(events)
      return events unless params[:last_fetched_at].present?

      last_fetched_at = params[:last_fetched_at] - NotesFinder::FETCH_OVERLAP

      events.created_after(last_fetched_at)
    end

    def resource_parent
      resource.try(:resource_parent) || resource.project || resource.group
    end
    strong_memoize_attr :resource_parent

    def table_name
      raise NotImplementedError
    end
  end
end
