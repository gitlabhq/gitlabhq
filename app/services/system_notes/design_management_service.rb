# frozen_string_literal: true

module SystemNotes
  class DesignManagementService < ::SystemNotes::BaseService
    include ActionView::RecordIdentifier

    # Parameters:
    #   - version [DesignManagement::Version]
    #
    # Example Note text:
    #
    #   "added [1 designs](link-to-version)"
    #   "changed [2 designs](link-to-version)"
    #
    # Returns [Array<Note>]: the created Note objects
    def design_version_added(version)
      events = DesignManagement::Action.events
      link_href = designs_path(version: version.id)

      version.designs_by_event.map do |(event_name, designs)|
        note_data = self.class.design_event_note_data(events[event_name])
        icon_name = note_data[:icon]
        n = designs.size

        body = "%s [%d %s](%s)" % [note_data[:past_tense], n, 'design'.pluralize(n), link_href]

        create_note(NoteSummary.new(noteable, project, author, body, action: icon_name))
      end
    end

    # Called when a new discussion is created on a design
    #
    # discussion_note - DiscussionNote
    #
    # Example Note text:
    #
    #   "started a discussion on screen.png"
    #
    # Returns the created Note object
    def design_discussion_added(discussion_note)
      design = discussion_note.noteable

      body = _('started a discussion on %{design_link}') % {
        design_link: '[%s](%s)' % [
          design.filename,
          designs_path(vueroute: design.filename, anchor: dom_id(discussion_note))
        ]
      }

      action = :designs_discussion_added

      create_note(NoteSummary.new(noteable, project, author, body, action: action))
    end

    # Take one of the `DesignManagement::Action.events` and
    # return:
    #   * an English past-tense verb.
    #   * the name of an icon used in renderin a system note
    #
    # We do not currently internationalize our system notes,
    # instead we just produce English-language descriptions.
    # See: https://gitlab.com/gitlab-org/gitlab/issues/30408
    # See: https://gitlab.com/gitlab-org/gitlab/issues/14056
    def self.design_event_note_data(event)
      case event
      when DesignManagement::Action.events[:creation]
        { icon: 'designs_added', past_tense: 'added' }
      when DesignManagement::Action.events[:modification]
        { icon: 'designs_modified', past_tense: 'updated' }
      when DesignManagement::Action.events[:deletion]
        { icon: 'designs_removed', past_tense: 'removed' }
      else
        raise "Unknown event: #{event}"
      end
    end

    private

    def designs_path(params = {})
      url_helpers.designs_project_issue_path(project, noteable, params)
    end
  end
end
