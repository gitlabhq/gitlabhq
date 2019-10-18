# frozen_string_literal: true

module Issues
  class ZoomLinkService < Issues::BaseService
    def initialize(issue, user)
      super(issue.project, user)

      @issue = issue
    end

    def add_link(link)
      if can_add_link? && (link = parse_link(link))
        track_meeting_added_event
        success(_('Zoom meeting added'), append_to_description(link))
      else
        error(_('Failed to add a Zoom meeting'))
      end
    end

    def can_add_link?
      can? && !link_in_issue_description?
    end

    def remove_link
      if can_remove_link?
        track_meeting_removed_event
        success(_('Zoom meeting removed'), remove_from_description)
      else
        error(_('Failed to remove a Zoom meeting'))
      end
    end

    def can_remove_link?
      can? && link_in_issue_description?
    end

    def parse_link(link)
      Gitlab::ZoomLinkExtractor.new(link).links.last
    end

    private

    attr_reader :issue

    def issue_description
      issue.description || ''
    end

    def track_meeting_added_event
      ::Gitlab::Tracking.event('IncidentManagement::ZoomIntegration', 'add_zoom_meeting', label: 'Issue ID', value: issue.id)
    end

    def track_meeting_removed_event
      ::Gitlab::Tracking.event('IncidentManagement::ZoomIntegration', 'remove_zoom_meeting', label: 'Issue ID', value: issue.id)
    end

    def success(message, description)
      ServiceResponse
        .success(message: message, payload: { description: description })
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def append_to_description(link)
      "#{issue_description}\n\n#{link}"
    end

    def remove_from_description
      link = parse_link(issue_description)
      return issue_description unless link

      issue_description.delete_suffix(link).rstrip
    end

    def link_in_issue_description?
      link = extract_link_from_issue_description
      return unless link

      Gitlab::ZoomLinkExtractor.new(link).match?
    end

    def extract_link_from_issue_description
      issue_description[/(\S+)\z/, 1]
    end

    def can?
      current_user.can?(:update_issue, project)
    end
  end
end
