# frozen_string_literal: true

module DiffViewer
  module ServerSide
    extend ActiveSupport::Concern

    included do
      self.collapse_limit = 1.megabyte
      self.size_limit = 5.megabytes
    end

    def prepare!
      diff_file.old_blob&.load_all_data!
      diff_file.new_blob&.load_all_data!
    end

    def render_error
      # Files that are not stored in the repository, like LFS files and
      # build artifacts, can only be rendered using a client-side viewer,
      # since we do not want to read large amounts of data into memory on the
      # server side. Client-side viewers use JS and can fetch the file from
      # `diff_file_blob_raw_path` and `diff_file_old_blob_raw_path` using AJAX.
      return :server_side_but_stored_externally if diff_file.stored_externally?

      super
    end
  end
end
