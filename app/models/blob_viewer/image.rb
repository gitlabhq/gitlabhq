# frozen_string_literal: true

module BlobViewer
  class Image < Base
    include Rich
    include ClientSide

    self.partial_name = 'image'
    self.extensions = UploaderHelper::SAFE_IMAGE_EXT
    self.binary = true
    self.switcher_icon = 'doc-image'
    self.switcher_title = 'image'
  end
end
