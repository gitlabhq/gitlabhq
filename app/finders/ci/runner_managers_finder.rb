# frozen_string_literal: true

module Ci
  class RunnerManagersFinder
    def initialize(runner:, params:)
      @runner = runner
      @params = params
    end

    def execute
      items = ::Ci::RunnerManager.for_runner(runner)

      items = by_status(items)
      items = by_system_id(items)

      sort_items(items)
    end

    private

    attr_reader :runner, :params

    def by_status(items)
      status = params[:status]
      return items if status.nil?

      items.with_status(status)
    end

    def by_system_id(items)
      system_id = params[:system_id]
      return items if system_id.nil?

      items.with_system_xid(system_id)
    end

    def sort_items(items)
      items.order_id_desc
    end
  end
end
