# frozen_string_literal: true

module Projects
  module MergeRequests
    class DiffsStreamController < Projects::MergeRequests::ApplicationController
      include RapidDiffs::StreamingResource

      private

      def diff_file_component(diff_file)
        ::RapidDiffs::MergeRequestDiffFileComponent.new(
          diff_file: diff_file, merge_request: @merge_request,
          parallel_view: view == :parallel
        )
      end

      def diff_files_collection(diff_files)
        ::RapidDiffs::MergeRequestDiffFileComponent.with_collection(
          diff_files, merge_request: @merge_request,
          parallel_view: view == :parallel
        )
      end

      def streaming_diff_options
        return rapid_diff_options unless Feature.enabled?(:rapid_diffs_on_mr_show, current_user, type: :beta)

        rapid_diff_options.merge(only_context_commits: show_only_context_commits?)
      end
    end
  end
end
