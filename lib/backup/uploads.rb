require 'backup/files'

module Backup
  class Uploads < Files

    def initialize
      super('uploads', Rails.root.join('public/uploads'))
    end

    def create_files_dir
      Dir.mkdir(app_files_dir)
    end
  end
end
