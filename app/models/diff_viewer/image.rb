# frozen_string_literal: true

module DiffViewer
  class Image < Base
    include Rich
    include ClientSide

    self.partial_name = 'image'
    self.extensions = UploaderHelper::SAFE_IMAGE_EXT
    self.binary = true
    self.switcher_icon = 'doc-image'
    self.switcher_title = _('image diff')
  end
end
