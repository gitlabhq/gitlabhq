require 'backup/files'

module Backup
  class Artifacts < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('artifacts', JobArtifactUploader.root)
    end
  end
end
