require 'backup/files'

module Backup
  class Registry < Files
    def initialize
      super('registry', Settings.registry.path)
    end
  end
end
