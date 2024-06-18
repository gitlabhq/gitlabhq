# frozen_string_literal: true

module RapidDiffs
  class DiffFileComponent < ViewComponent::Base
    def initialize(diff_file:)
      @diff_file = diff_file
    end

    def viewer
      @diff_file.has_renderable? ? @diff_file.rendered.viewer : @diff_file.viewer
    end
  end
end
