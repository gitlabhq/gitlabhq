# frozen_string_literal: true

module Projects
  module MergeRequests
    class DiffsStreamController < Projects::MergeRequests::ApplicationController
      include ActionController::Live

      urgency :low, [:diffs]

      def diffs
        return render_404 unless ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)

        stream_headers

        offset = params[:offset].to_i

        # NOTE: This is a temporary flag to test out the new diff_blobs
        if !!ActiveModel::Type::Boolean.new.cast(params[:diff_blobs])
          stream_diff_blobs(offset)
        else
          stream_diff_files(offset)
        end

      rescue StandardError => e
        Gitlab::AppLogger.error("Error streaming diffs: #{e.message}")
        response.stream.write e.message
      ensure
        response.stream.close
      end

      private

      def view
        helpers.diff_view
      end

      def stream_diff_blobs(offset)
        @merge_request.diffs_for_streaming(offset_index: offset) do |diff_files_batch|
          diff_files_batch.each do |diff_file|
            response.stream.write(render_diff_file(diff_file))
          end
        end
      end

      def stream_diff_files(offset)
        @merge_request.diffs_for_streaming(offset_index: offset).diff_files.each do |diff_file|
          response.stream.write(render_diff_file(diff_file))
        end
      end

      def render_diff_file(diff_file)
        render_to_string(
          ::RapidDiffs::DiffFileComponent.new(diff_file: diff_file, parallel_view: view == :parallel),
          layout: false
        )
      end
    end
  end
end
