require 'backup/files'

module Backup
  class Pages < Files
    def initialize
      super('pages', Gitlab.config.pages.path)
    end

    def create_files_dir
      Dir.mkdir(app_files_dir, 0700)
    end
  end
end
