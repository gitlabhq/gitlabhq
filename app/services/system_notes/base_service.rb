# frozen_string_literal: true

module SystemNotes
  class BaseService
    attr_accessor :project, :group
    attr_reader :noteable, :container, :author

    def initialize(container: nil, noteable: nil, author: nil)
      @container = container
      @noteable = noteable
      @author = author

      handle_container_type(container)
    end

    protected

    def create_note(note_summary, skip_touch_noteable: false)
      note_params = note_summary.note.merge(system: true, skip_touch_noteable: skip_touch_noteable)
      note_params[:system_note_metadata] = SystemNoteMetadata.new(note_summary.metadata) if note_summary.metadata?

      Note.create(note_params)
    end

    def content_tag(...)
      ActionController::Base.helpers.content_tag(...)
    end

    def url_helpers
      @url_helpers ||= Gitlab::Routing.url_helpers
    end

    def handle_container_type(container)
      case container
      when Project, Namespaces::ProjectNamespace
        @project = container.owner_entity
      when Group
        @group = container
      end
    end
  end
end
