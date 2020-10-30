# frozen_string_literal: true

module API
  class ResourceStateEvents < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    {
      Issue => :issue_tracking,
      MergeRequest => :code_review
    }.each do |eventable_class, feature_category|
      eventable_name = eventable_class.to_s.underscore

      params do
        requires :id, type: String, desc: "The ID of a project"
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{eventable_class.to_s.downcase} resource state events" do
          success Entities::ResourceStateEvent
        end
        params do
          requires :eventable_iid, types: Integer, desc: "The IID of the #{eventable_name}"
          use :pagination
        end

        get ":id/#{eventable_name.pluralize}/:eventable_iid/resource_state_events", feature_category: feature_category do
          eventable = find_noteable(eventable_class, params[:eventable_iid])

          events = ResourceStateEventFinder.new(current_user, eventable).execute

          present paginate(events), with: Entities::ResourceStateEvent
        end

        desc "Get a single #{eventable_class.to_s.downcase} resource state event" do
          success Entities::ResourceStateEvent
        end
        params do
          requires :eventable_iid, types: Integer, desc: "The IID of the #{eventable_name}"
          requires :event_id, type: Integer, desc: 'The ID of a resource state event'
        end
        get ":id/#{eventable_name.pluralize}/:eventable_iid/resource_state_events/:event_id", feature_category: feature_category do
          eventable = find_noteable(eventable_class, params[:eventable_iid])

          event = ResourceStateEventFinder.new(current_user, eventable).find(params[:event_id])

          present event, with: Entities::ResourceStateEvent
        end
      end
    end
  end
end
