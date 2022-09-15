# frozen_string_literal: true

module API
  class ResourceStateEvents < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    Helpers::ResourceEventsHelpers.eventable_types.each do |eventable_type, details|
      parent_type = eventable_type.parent_class.to_s.underscore
      eventables_str = eventable_type.to_s.underscore.pluralize
      human_eventable_str = eventable_type.to_s.underscore.humanize.downcase
      feature_category = details[:feature_category]

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{human_eventable_str} resource state events" do
          success Entities::ResourceStateEvent
        end
        params do
          requires :eventable_id, types: Integer, desc: "The #{details[:id_field]} of the #{human_eventable_str}"
          use :pagination
        end

        get ":id/#{eventables_str}/:eventable_id/resource_state_events", feature_category: feature_category, urgency: :low do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          events = ResourceStateEventFinder.new(current_user, eventable).execute

          present paginate(events), with: Entities::ResourceStateEvent
        end

        desc "Get a single #{human_eventable_str} resource state event" do
          success Entities::ResourceStateEvent
        end
        params do
          requires :eventable_id, types: Integer, desc: "The #{details[:id_field]} of the #{human_eventable_str}"
          requires :event_id, type: Integer, desc: 'The ID of a resource state event'
        end
        get ":id/#{eventables_str}/:eventable_id/resource_state_events/:event_id", feature_category: feature_category do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          event = ResourceStateEventFinder.new(current_user, eventable).find(params[:event_id])

          present event, with: Entities::ResourceStateEvent
        end
      end
    end
  end
end
