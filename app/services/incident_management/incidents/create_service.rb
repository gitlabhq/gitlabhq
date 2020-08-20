# frozen_string_literal: true

module IncidentManagement
  module Incidents
    class CreateService < BaseService
      ISSUE_TYPE = 'incident'

      def initialize(project, current_user, title:, description:)
        super(project, current_user)

        @title = title
        @description = description
      end

      def execute
        issue = Issues::CreateService.new(
          project,
          current_user,
          title: title,
          description: description,
          label_ids: [find_or_create_incident_label.id],
          issue_type: ISSUE_TYPE
        ).execute

        return error(issue.errors.full_messages.to_sentence, issue) unless issue.valid?

        success(issue)
      end

      private

      attr_reader :title, :description

      def find_or_create_incident_label
        IncidentManagement::CreateIncidentLabelService
          .new(project, current_user)
          .execute
          .payload[:label]
      end

      def success(issue)
        ServiceResponse.success(payload: { issue: issue })
      end

      def error(message, issue = nil)
        ServiceResponse.error(payload: { issue: issue }, message: message)
      end
    end
  end
end
