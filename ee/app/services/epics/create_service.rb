module Epics
  class CreateService < IssuableBaseService
    attr_reader :group

    def initialize(group, current_user, params)
      @group, @current_user, @params = group, current_user, params
    end

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
