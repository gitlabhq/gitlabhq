require 'backup/files'

module Backup
  class Uploads < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('uploads', Rails.root.join('public/uploads'))
    end
  end
end
