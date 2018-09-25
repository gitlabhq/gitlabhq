# frozen_string_literal: true

module Epics
  class ReopenService < Epics::BaseService
    def execute(epic)
      return epic unless can?(current_user, :update_epic, epic)

      epic.reopen
      epic
    end
  end
end
