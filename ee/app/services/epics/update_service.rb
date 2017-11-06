module Epics
  class UpdateService < ::IssuableBaseService
    def execute(epic)
      update(epic)
    end
  end
end
