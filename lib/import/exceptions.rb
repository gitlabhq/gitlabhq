# frozen_string_literal: true

module Import
  module Exceptions
    class SidekiqExhaustedInterruptionsError < StandardError
      def initialize(message = nil)
        super(message || "Import process reached the maximum number of interruptions")
      end
    end
  end
end
