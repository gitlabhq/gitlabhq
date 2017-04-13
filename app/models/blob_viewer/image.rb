module BlobViewer
  class Image < Base
    include Rich
    include ClientSide

    self.partial_name = 'image'
    self.extensions = UploaderHelper::IMAGE_EXT
    self.text_based = false
    self.switcher_icon = 'picture-o'
    self.switcher_title = 'image'
  end
end
