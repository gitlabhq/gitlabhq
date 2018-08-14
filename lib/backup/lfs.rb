require 'backup/files'

module Backup
  class Lfs < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('lfs', Settings.lfs.storage_path)
    end
  end
end
