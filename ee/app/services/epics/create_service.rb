module Epics
  class CreateService < Epics::BaseService
    def execute
      @epic = group.epics.new(whitelisted_epic_params)
      create(@epic)
    end

    private

    def whitelisted_epic_params
      params.slice(:title, :description, :start_date, :end_date)
    end
  end
end
