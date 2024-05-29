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

        @merge_request.diffs(offset_index: offset).diff_files.each do |diff|
          response.stream.write(
            render_to_string(
              ::RapidDiffs::DiffFileComponent.new(diff_file: diff),
              layout: false
            )
          )
        end

      rescue StandardError => e
        response.stream.write e.message
      ensure
        response.stream.close
      end
    end
  end
end
