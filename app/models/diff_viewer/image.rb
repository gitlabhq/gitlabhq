# frozen_string_literal: true

module DiffViewer
  class Image < Base
    include Rich
    include ClientSide

    self.partial_name = 'image'
    self.extensions = UploaderHelper::IMAGE_EXT
    self.binary = true
    self.switcher_icon = 'picture-o'
    self.switcher_title = 'image diff'
  end
end
