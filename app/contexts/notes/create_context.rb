module Notes
  class CreateContext < BaseContext
    def execute
      note = project.notes.new(params[:note])
      note.author = current_user
      note.notify = params[:notify].present?
      note.notify_author = params[:notify_author].present?
      note.save
      note
    end
  end
end
