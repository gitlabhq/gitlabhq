module Notes
  class CreateContext < BaseContext
    def execute
      note = project.notes.new(params[:note])
      note.author = current_user
      note.notify = true if params[:notify] == '1'
      note.notify_author = true if params[:notify_author] == '1'
      note.save
      note
    end
  end
end
