# frozen_string_literal: true

module IncidentManagement
  module TimelineEventTags
    class CreateService
      attr_reader :project, :user, :params

      def initialize(project, user, params)
        @project = project
        @user = user
        @params = params
      end

      def execute
        unless allowed?
          return error(_('You have insufficient permissions to manage timeline event tags for this project'))
        end

        timeline_event_tag_params = {
          project: project,
          name: params[:name]
        }

        timeline_event_tag = IncidentManagement::TimelineEventTag.new(timeline_event_tag_params)

        if timeline_event_tag.save
          ServiceResponse.success(payload: { timeline_event_tag: timeline_event_tag })
        else
          error(timeline_event_tag.errors.full_messages.to_sentence)
        end
      end

      private

      def allowed?
        user&.can?(:create_timeline_event_tag, project)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
