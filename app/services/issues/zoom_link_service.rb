# frozen_string_literal: true

module Issues
  class ZoomLinkService < Issues::BaseService
    def initialize(issue, user)
      super(issue.project, user)

      @issue = issue
      @added_meeting = ZoomMeeting.canonical_meeting(@issue)
    end

    def add_link(link)
      if can_add_link? && (link = parse_link(link))
        begin
          add_zoom_meeting(link)
          success(_('Zoom meeting added'))
        rescue ActiveRecord::RecordNotUnique
          error(_('Failed to add a Zoom meeting'))
        end
      else
        error(_('Failed to add a Zoom meeting'))
      end
    end

    def remove_link
      if can_remove_link?
        remove_zoom_meeting
        success(_('Zoom meeting removed'))
      else
        error(_('Failed to remove a Zoom meeting'))
      end
    end

    def can_add_link?
      can_update_issue? && !@added_meeting
    end

    def can_remove_link?
      can_update_issue? && !!@added_meeting
    end

    def parse_link(link)
      Gitlab::ZoomLinkExtractor.new(link).links.last
    end

    private

    attr_reader :issue

    def track_meeting_added_event
      ::Gitlab::Tracking.event('IncidentManagement::ZoomIntegration', 'add_zoom_meeting', label: 'Issue ID', value: issue.id)
    end

    def track_meeting_removed_event
      ::Gitlab::Tracking.event('IncidentManagement::ZoomIntegration', 'remove_zoom_meeting', label: 'Issue ID', value: issue.id)
    end

    def add_zoom_meeting(link)
      ZoomMeeting.create(
        issue: @issue,
        project: @issue.project,
        issue_status: :added,
        url: link
      )
      track_meeting_added_event
      SystemNoteService.zoom_link_added(@issue, @project, current_user)
    end

    def remove_zoom_meeting
      @added_meeting.update(issue_status: :removed)
      track_meeting_removed_event
      SystemNoteService.zoom_link_removed(@issue, @project, current_user)
    end

    def success(message)
      ServiceResponse.success(message: message)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def can_update_issue?
      can?(current_user, :update_issue, project)
    end
  end
end
