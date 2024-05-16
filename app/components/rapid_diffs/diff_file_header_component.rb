# frozen_string_literal: true

module RapidDiffs
  class DiffFileHeaderComponent < ViewComponent::Base
    def initialize(diff_file:)
      @diff_file = diff_file
    end
  end
end
