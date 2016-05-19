require 'backup/files'

module Backup
  class Registry < Files
    def initialize
      super('registry', Settings.registry.path)
    end

    def create_files_dir
      Dir.mkdir(app_files_dir, 0700)
    end
  end
end
