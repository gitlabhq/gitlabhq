require 'backup/files'

module Backup
  class Builds < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('builds', Settings.gitlab_ci.builds_path)
    end
  end
end
