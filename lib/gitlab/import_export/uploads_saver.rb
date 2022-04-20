# frozen_string_literal: true

module Gitlab
  module ImportExport
    class UploadsSaver
      include DurationMeasuring

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        with_duration_measuring do
          Gitlab::ImportExport::UploadsManager.new(
            project: @project,
            shared: @shared
          ).save
        end
      rescue StandardError => e
        @shared.error(e)
        false
      end
    end
  end
end
