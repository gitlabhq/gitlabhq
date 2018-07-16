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

        Gitlab::ImportExport::UploadsManager.new(
          project: @project,
          shared: @shared,
          relative_export_path: 'avatar',
          from: avatar_path
        ).save
      rescue => e
        @shared.error(e)
        false
      end

      private

      def avatar_path
        @project.avatar.path
      end
    end
  end
end
