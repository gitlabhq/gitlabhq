# frozen_string_literal: true

module Gitlab
  module ImportExport
    class AvatarRestorer
      include ::Import::Framework::ProgressTracking

      attr_accessor :project

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def restore
        return true unless avatar_export_file

        with_progress_tracking(**progress_tracking_options) do
          @project.avatar = File.open(avatar_export_file)
          @project.save!
        end
      rescue StandardError => e
        @shared.error(e)
        false
      end

      private

      def avatar_export_file
        @avatar_export_file ||= Dir["#{avatar_export_path}/**/*"].find { |f| File.file?(f) }
      end

      def avatar_export_path
        File.join(@shared.export_path, 'avatar')
      end

      def progress_tracking_options
        { scope: { project_id: @project.id }, data: 'avatar' }
      end
    end
  end
end
