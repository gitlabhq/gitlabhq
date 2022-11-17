# frozen_string_literal: true

module IncidentManagement
  module TimelineEventTags
    class CreateService < TimelineEventTags::BaseService
      attr_reader :project, :user, :params

      def initialize(project, user, params)
        @project = project
        @user = user
        @params = params
      end

      def execute
        return error_no_permissions unless allowed?

        timeline_event_tag_params = {
          project: project,
          name: params[:name]
        }

        timeline_event_tag = IncidentManagement::TimelineEventTag.new(timeline_event_tag_params)

        if timeline_event_tag.save
          success(timeline_event_tag)
        else
          error_in_save(timeline_event_tag)
        end
      end
    end
  end
end
