module Teams
  class RemoveContext < Teams::BaseContext
    def execute
      team.destroy
    end
  end
end
