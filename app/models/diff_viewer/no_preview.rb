# frozen_string_literal: true

module DiffViewer
  class NoPreview < Base
    include Simple
    include Static

    self.partial_name = 'no_preview'
    self.binary = true
  end
end
