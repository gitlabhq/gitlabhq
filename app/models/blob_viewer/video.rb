# frozen_string_literal: true

module BlobViewer
  class Video < Base
    include Rich
    include ClientSide

    self.partial_name = 'video'
    self.extensions = UploaderHelper::SAFE_VIDEO_EXT
    self.binary = true
  end
end
