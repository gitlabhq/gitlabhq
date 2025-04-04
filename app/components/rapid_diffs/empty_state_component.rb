# frozen_string_literal: true

module RapidDiffs
  class EmptyStateComponent < ViewComponent::Base
    def initialize(message: nil)
      @message = message || _('There are no changes')
    end

    private

    attr_reader :message
  end
end
