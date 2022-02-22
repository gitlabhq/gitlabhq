# frozen_string_literal: true

module Blobs
  class NotebookPresenter < ::BlobPresenter
    def gitattr_language
      'md'
    end
  end
end
