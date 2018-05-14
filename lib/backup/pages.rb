require 'backup/files'

module Backup
  class Pages < Files
    def initialize
      super('pages', Gitlab.config.pages.path)
    end
  end
end
