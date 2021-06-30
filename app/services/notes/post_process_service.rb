# frozen_string_literal: true

module Notes
  class PostProcessService
    attr_accessor :note

    def initialize(note)
      @note = note
    end

    def execute
      # Skip system notes, like status changes and cross-references and awards
      unless note.system?
        EventCreateService.new.leave_note(note, note.author)

        return if note.for_personal_snippet?

        note.create_cross_references!
        ::SystemNoteService.design_discussion_added(note) if create_design_discussion_system_note?

        execute_note_hooks
      end
    end

    private

    def create_design_discussion_system_note?
      note && note.for_design? && note.start_of_discussion?
    end

    def hook_data
      Gitlab::DataBuilder::Note.build(note, note.author)
    end

    def execute_note_hooks
      return unless note.project

      note_data = hook_data
      hooks_scope = note.confidential?(include_noteable: true) ? :confidential_note_hooks : :note_hooks

      note.project.execute_hooks(note_data, hooks_scope)
      note.project.execute_integrations(note_data, hooks_scope)
    end
  end
end

Notes::PostProcessService.prepend_mod_with('Notes::PostProcessService')
