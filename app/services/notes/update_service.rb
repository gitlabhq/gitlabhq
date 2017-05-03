module Notes
  class UpdateService < BaseService
    def execute(note)
      return note unless note.editable?

      note.update_attributes(params.merge(updated_by: current_user))
      note.create_new_cross_references!(current_user)

      if note.previous_changes.include?('note')
        TodoService.new.update_note(note, current_user)
      end

      note
    end
  end
end
