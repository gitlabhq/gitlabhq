module Notes
  class DestroyService < BaseService
    def execute(note)
      note.destroy
    end
  end
end
