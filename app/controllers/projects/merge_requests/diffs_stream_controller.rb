# frozen_string_literal: true

module Projects
  module MergeRequests
    class DiffsStreamController < Projects::MergeRequests::ApplicationController
      include RapidDiffs::StreamingResource

      private

      def resource
        @merge_request
      end

      def diff_file_component(diff_file)
        ::RapidDiffs::MergeRequestDiffFileComponent
          .new(diff_file: diff_file, merge_request: @merge_request, parallel_view: view == :parallel)
      end

      def diff_files_collection(diff_files)
        ::RapidDiffs::MergeRequestDiffFileComponent
          .with_collection(diff_files, merge_request: @merge_request, parallel_view: view == :parallel)
      end

      def sorted?
        true
      end
    end
  end
end
