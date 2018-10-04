# frozen_string_literal: true

module BlobViewer
  class Video < Base
    include Rich
    include ClientSide

    self.partial_name = 'video'
    self.extensions = UploaderHelper::VIDEO_EXT
    self.binary = true
    self.switcher_icon = 'film'
    self.switcher_title = 'video'
  end
end
