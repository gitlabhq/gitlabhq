# frozen_string_literal: true

module Gitlab
  module ImportExport
    class AvatarSaver
      include DurationMeasuring

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        with_duration_measuring do
          break true unless @project.avatar.exists?

          Gitlab::ImportExport::UploadsManager.new(
            project: @project,
            shared: @shared,
            relative_export_path: 'avatar'
          ).save
        end
      rescue StandardError => e
        @shared.error(e)
        false
      end
    end
  end
end
