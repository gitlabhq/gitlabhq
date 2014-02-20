module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params[:note])
      note.author = current_user
      note.system = false
      note.save
      note
    end
  end
end
