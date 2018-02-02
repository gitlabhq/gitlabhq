require 'backup/files'

module Backup
  class Artifacts < Files
    def initialize
      super('artifacts', JobArtifactUploader.root)
    end

    def create_files_dir
      Dir.mkdir(app_files_dir, 0700)
    end
  end
end
