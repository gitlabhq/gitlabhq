# frozen_string_literal: true

module API
  class ResourceMilestoneEvents < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    resource_milestone_events_tags = %w[resource_milestone_events]

    before { authenticate! }

    {
      Issue => :team_planning,
      MergeRequest => :code_review_workflow
    }.each do |eventable_type, feature_category|
      parent_type = eventable_type.parent_class.to_s.underscore
      eventables_str = eventable_type.to_s.underscore.pluralize

      params do
        requires :id, types: [String, Integer], desc: "The ID or URL-encoded path of the #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "List project #{eventable_type.underscore.humanize} milestone events" do
          detail "Gets a list of all milestone events for a single #{eventable_type.underscore.humanize}"
          success Entities::ResourceMilestoneEvent
          is_array true
          tags resource_milestone_events_tags
        end
        params do
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
          use :pagination
        end
        get ":id/#{eventables_str}/:eventable_id/resource_milestone_events", feature_category: feature_category, urgency: :low do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          events = ResourceMilestoneEventFinder.new(current_user, eventable).execute

          present paginate(events), with: Entities::ResourceMilestoneEvent
        end

        desc "Get single #{eventable_type.underscore.humanize} milestone event" do
          detail "Returns a single milestone event for a specific project #{eventable_type.underscore.humanize}"
          success Entities::ResourceMilestoneEvent
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags resource_milestone_events_tags
        end
        params do
          requires :event_id, type: String, desc: 'The ID of a resource milestone event'
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
        end
        get ":id/#{eventables_str}/:eventable_id/resource_milestone_events/:event_id", feature_category: feature_category do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          event = eventable.resource_milestone_events.find(params[:event_id])

          not_found!('ResourceMilestoneEvent') unless can?(current_user, :read_milestone, event.milestone_parent)

          present event, with: Entities::ResourceMilestoneEvent
        end
      end
    end
  end
end
