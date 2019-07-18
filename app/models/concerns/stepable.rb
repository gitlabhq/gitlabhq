# frozen_string_literal: true

module Stepable
  extend ActiveSupport::Concern

  def steps
    self.class._all_steps
  end

  def execute_steps
    initial_result = {}

    steps.inject(initial_result) do |previous_result, callback|
      result = method(callback).call

      if result[:status] == :error
        result[:failed_step] = callback

        break result
      end

      previous_result.merge(result)
    end
  end

  class_methods do
    def _all_steps
      @_all_steps ||= []
    end

    def steps(*methods)
      _all_steps.concat methods
    end
  end
end
