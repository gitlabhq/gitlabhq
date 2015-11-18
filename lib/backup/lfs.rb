require 'backup/files'

module Backup
  class Lfs < Files
    def initialize
      super('lfs', Settings.lfs.storage_path)
    end

    def create_files_dir
      Dir.mkdir(app_files_dir, 0700)
    end
  end
end
