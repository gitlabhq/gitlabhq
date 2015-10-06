module Backup
  class Uploads < Files

    def initialize
      super(Rails.root.join('public/uploads'))
    end
  end
end
