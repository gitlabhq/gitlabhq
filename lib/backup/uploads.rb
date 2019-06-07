# frozen_string_literal: true

require 'backup/files'

module Backup
  class Uploads < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('uploads', File.join(Gitlab.config.uploads.storage_path, "uploads"))
    end
  end
end
