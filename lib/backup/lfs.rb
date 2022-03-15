# frozen_string_literal: true

module Backup
  class Lfs < Backup::Files
    def initialize(progress)
      super(progress, 'lfs', Settings.lfs.storage_path)
    end

    override :human_name
    def human_name
      _('lfs objects')
    end
  end
end
