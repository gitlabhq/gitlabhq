# frozen_string_literal: true

module Backup
  class Artifacts < Backup::Files
    def initialize(progress)
      super(progress, 'artifacts', JobArtifactUploader.root, excludes: ['tmp'])
    end

    override :human_name
    def human_name
      _('artifacts')
    end
  end
end
