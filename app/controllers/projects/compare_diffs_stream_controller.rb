# frozen_string_literal: true

module Projects
  class CompareDiffsStreamController < Projects::CompareController
    include RapidDiffs::StreamingResource

    private

    def resource
      compare
    end
  end
end
