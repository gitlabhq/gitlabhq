# frozen_string_literal: true

module Projects
  module MergeRequests
    class DiffsStreamController < Projects::MergeRequests::ApplicationController
      include StreamDiffs

      private

      def resource
        @merge_request
      end
    end
  end
end
