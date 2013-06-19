module Groups
  class RemoveContext < Groups::BaseContext
    def execute
      group.destroy
    end
  end
end
