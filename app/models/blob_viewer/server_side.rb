module BlobViewer
  module ServerSide
    extend ActiveSupport::Concern

    included do
      self.client_side = false
      self.max_size = 2.megabytes
      self.absolute_max_size = 5.megabytes
    end

    def prepare!
      if blob.project
        blob.load_all_data!(blob.project.repository)
      end
    end
  end
end
