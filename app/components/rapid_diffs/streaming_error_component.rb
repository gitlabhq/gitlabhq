# frozen_string_literal: true

module RapidDiffs
  class StreamingErrorComponent < ViewComponent::Base
    def initialize(message:)
      @message = message
    end
  end
end
