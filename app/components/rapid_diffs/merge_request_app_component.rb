# frozen_string_literal: true

module RapidDiffs
  class MergeRequestAppComponent < ViewComponent::Base
    attr_reader :presenter

    def initialize(presenter)
      @presenter = presenter
    end
  end
end
