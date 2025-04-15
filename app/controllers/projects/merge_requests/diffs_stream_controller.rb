# frozen_string_literal: true

module Projects
  module MergeRequests
    class DiffsStreamController < Projects::MergeRequests::ApplicationController
      include RapidDiffs::StreamingResource

      private

      def resource
        @merge_request
      end

      def render_diff_file(diff_file)
        render_to_string(
          ::RapidDiffs::MergeRequestDiffFileComponent.new(
            diff_file: diff_file,
            merge_request: @merge_request,
            parallel_view: view == :parallel
          ),
          layout: false
        )
      end
    end
  end
end
