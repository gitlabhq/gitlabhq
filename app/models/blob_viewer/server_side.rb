module BlobViewer
  module ServerSide
    extend ActiveSupport::Concern

    included do
      self.load_async = true
      self.max_size = 2.megabytes
      self.absolute_max_size = 5.megabytes
    end

    def prepare!
      if blob.project
        blob.load_all_data!(blob.project.repository)
      end
    end

    def render_error
      if blob.stored_externally?
        # Files that are not stored in the repository, like LFS files and
        # build artifacts, can only be rendered using a client-side viewer,
        # since we do not want to read large amounts of data into memory on the
        # server side. Client-side viewers use JS and can fetch the file from
        # `blob_raw_url` using AJAX.
        return :server_side_but_stored_externally
      end

      super
    end
  end
end
