# frozen_string_literal: true

module API
  class ResourceLabelEvents < ::API::Base
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
        desc "Get a list of #{human_eventable_str} resource label events" do
          success Entities::ResourceLabelEvent
          detail 'This feature was introduced in 11.3'
        end
        params do
          requires :eventable_id, types: [Integer, String], desc: "The #{details[:id_field]} of the #{human_eventable_str}"
          use :pagination
        end

        get ":id/#{eventables_str}/:eventable_id/resource_label_events", feature_category: feature_category, urgency: :low do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          events = eventable.resource_label_events.inc_relations

          present ResourceLabelEvent.visible_to_user?(current_user, paginate(events)), with: Entities::ResourceLabelEvent
        end

        desc "Get a single #{human_eventable_str} resource label event" do
          success Entities::ResourceLabelEvent
          detail 'This feature was introduced in 11.3'
        end
        params do
          requires :event_id, type: String, desc: 'The ID of a resource label event'
          requires :eventable_id, types: [Integer, String], desc: "The #{details[:id_field]} of the #{human_eventable_str}"
        end
        get ":id/#{eventables_str}/:eventable_id/resource_label_events/:event_id", feature_category: feature_category do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          event = eventable.resource_label_events.find(params[:event_id])

          not_found!('ResourceLabelEvent') unless can?(current_user, :read_resource_label_event, event)

          present event, with: Entities::ResourceLabelEvent
        end
      end
    end
  end
end
