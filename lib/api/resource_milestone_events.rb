# frozen_string_literal: true

module API
  class ResourceMilestoneEvents < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    {
      Issue => :issue_tracking,
      MergeRequest => :code_review
    }.each do |eventable_type, feature_category|
      parent_type = eventable_type.parent_class.to_s.underscore
      eventables_str = eventable_type.to_s.underscore.pluralize

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{eventable_type.to_s.downcase} resource milestone events" do
          success Entities::ResourceMilestoneEvent
        end
        params do
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
          use :pagination
        end

        get ":id/#{eventables_str}/:eventable_id/resource_milestone_events", feature_category: feature_category do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          events = ResourceMilestoneEventFinder.new(current_user, eventable).execute

          present paginate(events), with: Entities::ResourceMilestoneEvent
        end

        desc "Get a single #{eventable_type.to_s.downcase} resource milestone event" do
          success Entities::ResourceMilestoneEvent
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
