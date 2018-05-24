require 'backup/files'

module Backup
  class Registry < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('registry', Settings.registry.path)
    end
  end
end
