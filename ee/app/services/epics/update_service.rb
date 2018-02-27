module Epics
  class UpdateService < Epics::BaseService
    def execute(epic)
      update(epic)
    end
  end
end
