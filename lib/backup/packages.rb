# frozen_string_literal: true

module Backup
  class Packages < Backup::Files
    def initialize(progress)
      super(progress, 'packages', Settings.packages.storage_path, excludes: ['tmp'])
    end

    override :human_name
    def human_name
      _('packages')
    end
  end
end
