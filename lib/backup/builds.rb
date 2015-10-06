module Backup
  class Builds < Files
    def initialize
      super(Settings.gitlab_ci.builds_path)
    end
  end
end
