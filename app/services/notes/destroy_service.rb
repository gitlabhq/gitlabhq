module Notes
  class DestroyService < BaseService
    def execute(note)
      TodoService.new.destroy_target(note) do |note|
        note.destroy
      end
    end
  end
end
