# frozen_string_literal: true

module Backup
  class Lfs < Backup::Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('lfs', Settings.lfs.storage_path)
    end

    def human_name
      _('lfs objects')
    end
  end
end
