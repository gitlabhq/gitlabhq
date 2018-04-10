require 'backup/files'

module Backup
  class Lfs < Files
    def initialize
      super('lfs', Settings.lfs.storage_path)
    end
  end
end
