# frozen_string_literal: true

module Gitlab
  module Git
    class ChangedPath
      attr_reader :status, :path, :old_mode, :new_mode, :new_blob_id, :old_blob_id

      def initialize(status:, path:, old_mode:, new_mode:, new_blob_id: nil, old_blob_id: nil)
        @status = status
        @path = path
        @old_mode = old_mode
        @new_mode = new_mode
        @old_blob_id = old_blob_id
        @new_blob_id = new_blob_id
      end

      def new_file?
        status == :ADDED
      end

      def submodule_change?
        # The file mode 160000 represents a "Gitlink" or a git submodule.
        # The first two digits can be used to distinguish it from regular files.
        #
        # 160000 -> 16 -> gitlink
        # 100644 -> 10 -> regular file

        [old_mode, new_mode].any? { |mode| mode.starts_with?('16') }
      end
    end
  end
end
