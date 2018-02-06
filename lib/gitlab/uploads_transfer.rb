module Gitlab
  class UploadsTransfer < ProjectTransfer
    def root_dir
      FileUploader.root
    end
  end
end
