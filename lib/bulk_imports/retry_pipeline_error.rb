# frozen_string_literal: true

module BulkImports
  class RetryPipelineError < Error
    attr_reader :retry_delay

    def initialize(message, retry_delay = nil)
      super(message)

      @retry_delay = retry_delay
    end
  end
end
