module Gitlab
  module ImportExport
    class AvatarSaver
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        return true unless @project.avatar.exists?

        copy_files(avatar_path, avatar_export_path)
      rescue => e
        @shared.error(e)
        false
      end

      private

      def avatar_export_path
        File.join(@shared.export_path, 'avatar', @project.avatar_identifier)
      end

      def avatar_path
        @project.avatar.path
      end
    end
  end
end
