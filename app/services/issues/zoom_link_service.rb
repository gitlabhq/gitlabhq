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
        rescue ActiveRecord::RecordNotUnique
          error(message: _('Failed to add a Zoom meeting'))
        end
      else
        error(message: _('Failed to add a Zoom meeting'))
      end
    end

    def remove_link
      if can_remove_link?
        remove_zoom_meeting
        success(message: _('Zoom meeting removed'))
      else
        error(message: _('Failed to remove a Zoom meeting'))
      end
    end

    def can_add_link?
      can_change_link? && !@added_meeting
    end

    def can_remove_link?
      can_change_link? && @issue.persisted? && !!@added_meeting
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
      zoom_meeting = new_zoom_meeting(link)
      response =
        if @issue.persisted?
          # Save the meeting directly since we only want to update one meeting, not all
          zoom_meeting.save
          success(message: _('Zoom meeting added'))
        else
          success(message: _('Zoom meeting added'), payload: { zoom_meetings: [zoom_meeting] })
        end

      track_meeting_added_event
      SystemNoteService.zoom_link_added(@issue, @project, current_user)

      response
    end

    def new_zoom_meeting(link)
      ZoomMeeting.new(
        issue: @issue,
        project: @project,
        issue_status: :added,
        url: link
      )
    end

    def remove_zoom_meeting
      @added_meeting.update(issue_status: :removed)
      track_meeting_removed_event
      SystemNoteService.zoom_link_removed(@issue, @project, current_user)
    end

    def success(message:, payload: nil)
      ServiceResponse.success(message: message, payload: payload)
    end

    def error(message:)
      ServiceResponse.error(message: message)
    end

    def can_change_link?
      if @issue.persisted?
        can?(current_user, :update_issue, @project)
      else
        can?(current_user, :create_issue, @project)
      end
    end
  end
end
