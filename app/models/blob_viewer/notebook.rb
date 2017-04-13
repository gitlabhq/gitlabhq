module BlobViewer
  class Notebook < Base
    include Rich
    include ClientSide
    
    self.partial_name = 'notebook'
    self.extensions = %w(ipynb)
    self.text_based = true
    self.switcher_icon = 'file-text-o'
    self.switcher_title = 'notebook'
  end
end
