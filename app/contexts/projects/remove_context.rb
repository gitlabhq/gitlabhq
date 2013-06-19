module Projects
  class RemoveContext < Projects::BaseContext
    def execute
      project.destroy
    end
  end
end
