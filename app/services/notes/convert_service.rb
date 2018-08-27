module Notes
  class ConvertService < ::BaseService
    def execute(note)
      note.update!(type: DiscussionNote.to_s)
    end
  end
end
