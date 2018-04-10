require 'backup/files'

module Backup
  class Uploads < Files
    def initialize
      super('uploads', Rails.root.join('public/uploads'))
    end
  end
end
