# frozen_string_literal: true

module Admin
  class PlansFinder
    attr_reader :params

    def initialize(params = {})
      @params = params
    end

    def execute
      plans = Plan.all
      by_name(plans)
    end

    private

    def by_name(plans)
      return plans unless params[:name]

      Plan.find_by(name: params[:name])  # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
