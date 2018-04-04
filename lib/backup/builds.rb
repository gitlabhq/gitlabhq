require 'backup/files'

module Backup
  class Builds < Files
    def initialize
      super('builds', Settings.gitlab_ci.builds_path)
    end
  end
end
