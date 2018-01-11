module Workhorse
  module UploadPath
    def workhorse_upload_path
      File.join(root, base_dir, 'tmp/uploads')
    end
  end
end
