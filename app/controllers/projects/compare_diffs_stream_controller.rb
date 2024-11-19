# frozen_string_literal: true

module Projects
  class CompareDiffsStreamController < Projects::CompareController
    include StreamDiffs

    private

    def resource
      compare
    end
  end
end
