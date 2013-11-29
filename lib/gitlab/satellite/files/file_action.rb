module Gitlab
  module Satellite
    class FileAction < Action
      attr_accessor :file_path, :ref

      def initialize(user, project, ref, file_path)
        super user, project, git_timeout: 10.seconds
        @file_path = file_path
        @ref = ref
      end

      def safe_path?(path)
        File.absolute_path(path) == path
      end
    end
  end
end
