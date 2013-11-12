module Gitlab
  module Satellite
    class FileAction < Action
      attr_accessor :file_path, :ref

      def initialize(user, project, ref, file_path)
        super user, project, git_timeout: 10.seconds
        @file_path = file_path
        @ref = ref
      end
    end
  end
end
