# frozen_string_literal: true

module DesignManagement
  module OnSuccessCallbacks
    def on_success(&block)
      success_callbacks.push(block)
    end

    def success(*_)
      while cb = success_callbacks.pop
        cb.call
      end

      super
    end

    private

    def success_callbacks
      @success_callbacks ||= []
    end
  end
end
