module Notes
  class DeleteService < BaseService
    def execute(note)
      note.destroy
    end
  end
end
