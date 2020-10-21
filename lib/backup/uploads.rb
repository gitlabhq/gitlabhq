# frozen_string_literal: true

module Backup
  class Uploads < Backup::Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('uploads', File.join(Gitlab.config.uploads.storage_path, "uploads"), excludes: ['tmp'])
    end
  end
end
