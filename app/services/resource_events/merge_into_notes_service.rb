# frozen_string_literal: true

# We store events about issuable label changes in a separate table (not as
# other system notes), but we still want to display notes about label changes
# as classic system notes in UI.  This service generates "synthetic" notes for
# label event changes and merges them with classic notes and sorts them by
# creation time.

module ResourceEvents
  class MergeIntoNotesService
    include Gitlab::Utils::StrongMemoize

    attr_reader :resource, :current_user, :params

    def initialize(resource, current_user, params = {})
      @resource = resource
      @current_user = current_user
      @params = params
    end

    def execute(notes = [])
      (notes + label_notes).sort_by { |n| n.created_at }
    end

    private

    def label_notes
      label_events_by_discussion_id.map do |discussion_id, events|
        LabelNote.from_events(events, resource: resource, resource_parent: resource_parent)
      end
    end

    def label_events_by_discussion_id
      return [] unless resource.respond_to?(:resource_label_events)

      events = resource.resource_label_events.includes(:label, :user)
      events = since_fetch_at(events)

      events.group_by { |event| event.discussion_id }
    end

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
