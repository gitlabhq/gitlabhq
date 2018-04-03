module Notes
  class PostProcessService
    attr_accessor :note

    def initialize(note)
      @note = note
    end

    def execute
      # Skip system notes, like status changes and cross-references and awards
      unless @note.system?
        EventCreateService.new.leave_note(@note, @note.author)

        return if @note.for_personal_snippet?

        @note.create_cross_references!
        execute_note_hooks
      end
    end

    def hook_data
      Gitlab::DataBuilder::Note.build(@note, @note.author)
    end

    def execute_note_hooks
      note_data = hook_data
      hooks_scope = @note.confidential? ? :confidential_note_hooks : :note_hooks

      @note.project.execute_hooks(note_data, hooks_scope)
      @note.project.execute_services(note_data, hooks_scope)
    end
  end
end
