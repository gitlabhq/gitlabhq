# frozen_string_literal: true

module Projects
  module MergeRequests
    class DiffsStreamController < Projects::MergeRequests::ApplicationController
      include RapidDiffs::StreamingResource

      private

      def resource
        @merge_request
      end

      def render_diff_files_collection(diff_files, view_context)
        ::RapidDiffs::MergeRequestDiffFileComponent
          .with_collection(diff_files, merge_request: @merge_request, parallel_view: view == :parallel)
          .render_in(view_context)
      end

      def sorted?
        true
      end
    end
  end
end
