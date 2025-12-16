# frozen_string_literal: true

module Projects
  class CompareDiffsStreamController < Projects::CompareController
    include RapidDiffs::StreamingResource

    before_action :define_environment

    private

    def resource
      compare
    end
  end
end
