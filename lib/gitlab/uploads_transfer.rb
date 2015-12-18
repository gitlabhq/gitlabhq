module Gitlab
  class UploadsTransfer < ProjectTransfer
    def root_dir
      File.join(Rails.root, "public", "uploads")
    end
  end
end
