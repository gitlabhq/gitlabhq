require 'backup/files'

module Backup
  class Builds < Files
    def initialize
      super('builds', Settings.gitlab_ci.builds_path)
    end

    def create_files_dir
      Dir.mkdir(app_files_dir, 0700)
    end
  end
end
