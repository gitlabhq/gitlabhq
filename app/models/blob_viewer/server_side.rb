module BlobViewer
  module ServerSide
    extend ActiveSupport::Concern

    included do
      self.load_async = true
      self.collapse_limit = 2.megabytes
      self.size_limit = 5.megabytes
    end

    def prepare!
      blob.load_all_data!
    end

    def render_error
      # Files that are not stored in the repository, like LFS files and
      # build artifacts, can only be rendered using a client-side viewer,
      # since we do not want to read large amounts of data into memory on the
      # server side. Client-side viewers use JS and can fetch the file from
      # `blob_raw_path` using AJAX.
      return :server_side_but_stored_externally if blob.stored_externally?

      super
    end
  end
end
