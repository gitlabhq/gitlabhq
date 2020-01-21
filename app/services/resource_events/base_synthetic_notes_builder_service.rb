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

    def since_fetch_at(events)
      return events unless params[:last_fetched_at].present?

      last_fetched_at = Time.at(params.fetch(:last_fetched_at).to_i)
      events.created_after(last_fetched_at - NotesFinder::FETCH_OVERLAP)
    end

    def resource_parent
      strong_memoize(:resource_parent) do
        resource.project || resource.group
      end
    end
  end
end
