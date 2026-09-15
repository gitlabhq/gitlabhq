# frozen_string_literal: true

module SystemNotes
  class BaseService
    UnpersistedSystemNoteError = Class.new(StandardError)

    attr_accessor :project, :group
    attr_reader :noteable, :container, :author

    def initialize(container: nil, noteable: nil, author: nil)
      @container = container
      @noteable = noteable
      @author = Gitlab::Auth::Identity.resolve_composite_identity_actor(author)

      handle_container_type(container)
    end

    protected

    def create_note(note_summary, skip_touch_noteable: false)
      note_params = note_summary.note.merge(system: true, skip_touch_noteable: skip_touch_noteable)
      note_params[:system_note_metadata] = SystemNoteMetadata.new(note_summary.metadata) if note_summary.metadata?

      Note.create(note_params).tap do |note|
        track_unpersisted_note(note, note_summary) unless note.persisted?
      end
    end

    def content_tag(...)
      ActionController::Base.helpers.content_tag(...)
    end

    def url_helpers
      @url_helpers ||= Gitlab::Routing.url_helpers
    end

    # Reasons are spliced into sentences such as "... because #{reason}", and they
    # are produced all over the codebase, so some start with a capital letter. Note
    # bodies are persisted in English, so downcasing the first one is locale-safe.
    def format_reason(reason)
      return if reason.blank?

      reason.sub(/\A./, &:downcase)
    end

    def handle_container_type(container)
      case container
      when Project, Namespaces::ProjectNamespace
        @project = container.owner_entity
      when Group
        @group = container
      end
    end

    private

    def track_unpersisted_note(note, note_summary)
      Gitlab::ErrorTracking.track_exception(
        UnpersistedSystemNoteError.new('System note was not persisted'),
        noteable_type: note.noteable_type,
        noteable_id: note.noteable_id,
        # Commit notes store a nil noteable_id, so the SHA is the only identifier they have.
        commit_id: note.commit_id,
        note_action: note_summary.metadata[:action],
        note_errors: note.errors.full_messages,
        note_bytesize: note.note.to_s.bytesize
      )
    end
  end
end
