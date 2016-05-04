module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if note.save
        # Finish the harder work in the background
        NewNoteWorker.perform_in(2.seconds, note.id, params)
        TodoService.new.new_note(note, current_user)
      end

      note
    end

    # An issue can be create from a line comment. This issue has the specified format:
    #
    #
    # ## Title here
    # ---
    # description should be here
    #
    def new_issue
      lines       = params[:note].lines
      title       = lines[0].gsub(/\A.{3}\W*/, '').rstrip
      description = lines[2..-1].join('\n').strip # lines[1] == '---' and is thus discarded

      issue = Issues::CreateService.new(project, current_user, title: title, description: description).execute
      return issue unless issue.valid?

      params[:note] = "#{issue.to_reference} was created from this line comment."
      execute
    end
  end
end
