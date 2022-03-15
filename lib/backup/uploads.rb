# frozen_string_literal: true

module Backup
  class Uploads < Backup::Files
    def initialize(progress)
      super(progress, 'uploads', File.join(Gitlab.config.uploads.storage_path, "uploads"), excludes: ['tmp'])
    end

    override :human_name
    def human_name
      _('uploads')
    end
  end
end
