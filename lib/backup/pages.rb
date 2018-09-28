require 'backup/files'

module Backup
  class Pages < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('pages', Gitlab.config.pages.path)
    end
  end
end
