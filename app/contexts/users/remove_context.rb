module Users
  class RemoveContext < Users::BaseContext
    def execute
      user.destroy
    end
  end
end
