# frozen_string_literal: true

module RapidDiffs
  class EmptyStateComponent < ViewComponent::Base
    def initialize(message: nil, description: nil)
      @message = message || _('There are no changes')
      @description = description
    end

    private

    attr_reader :message, :description
  end
end
