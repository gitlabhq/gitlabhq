module Gitlab
  module ImportExport
    class UploadsSaver
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        Gitlab::ImportExport::UploadsManager.new(
          project: @project,
          shared: @shared
        ).save
      rescue => e
        @shared.error(e)
        false
      end
    end
  end
end
