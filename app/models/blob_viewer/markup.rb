# frozen_string_literal: true

module BlobViewer
  class Markup < Base
    include Rich
    include ServerSide

    self.partial_name = 'markup'
    self.extensions = Gitlab::MarkupHelper::EXTENSIONS
    self.file_types = %i(readme)
    self.binary = false
  end
end
