module Gitlab
  module ImportExport
    class AvatarRestorer
      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def restore
        return true unless avatar_export_file

        @project.avatar = File.open(avatar_export_file)
        @project.save!
      rescue => e
        @shared.error(e)
        false
      end

      private

      def avatar_export_file
        @avatar_export_file ||= Dir["#{avatar_export_path}/**/*"].first
      end

      def avatar_export_path
        File.join(@shared.export_path, 'avatar')
      end
    end
  end
end
