module Gitlab
  class UploadsTransfer < ProjectTransfer
    def root_dir
      File.join(CarrierWave.root, FileUploader.base_dir)
    end
  end
end
