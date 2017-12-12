module Gitlab
  class UploadsTransfer < ProjectTransfer
    def root_dir
      File.join(*Gitlab.config.uploads.values_at('storage_path', 'base_dir'))
    end
  end
end
