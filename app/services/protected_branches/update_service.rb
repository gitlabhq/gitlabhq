module ProtectedBranches
  class UpdateService < ProtectedBranches::BaseService
    attr_reader :protected_branch

    def initialize(project, current_user, id, params = {})
      super(project, current_user, params)
      @id = id
    end

    def execute
      ProtectedBranch.transaction do
        @protected_branch = ProtectedBranch.find(@id)
        set_access_levels!
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
