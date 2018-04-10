require 'backup/files'

module Backup
  class Artifacts < Files
    def initialize
      super('artifacts', JobArtifactUploader.root)
    end
  end
end
