module BlobViewer
  class PDF < Base
    include Rich
    include ClientSide
    
    self.partial_name = 'pdf'
    self.extensions = %w(pdf)
    self.text_based = false
    self.switcher_icon = 'file-pdf-o'
    self.switcher_title = 'PDF'
  end
end
