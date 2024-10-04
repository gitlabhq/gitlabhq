# frozen_string_literal: true

module Projects
  module MergeRequests
    class DiffsStreamController < Projects::MergeRequests::ApplicationController
      include StreamDiffs

      private

      def resource
        @merge_request
      end

      def options
        {}
      end

      def stream_diff_files(options)
        if !!ActiveModel::Type::Boolean.new.cast(params[:diff_blobs])
          stream_diff_blobs(options)
        else
          super
        end
      end

      def stream_diff_blobs(options)
        @merge_request.diffs_for_streaming(options) do |diff_files_batch|
          diff_files_batch.each do |diff_file|
            response.stream.write(render_diff_file(diff_file))
          end
        end
      end
    end
  end
end
