# frozen_string_literal: true

module Backup
  class Packages < Backup::Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('packages', Settings.packages.storage_path, excludes: ['tmp'])
    end
  end
end
