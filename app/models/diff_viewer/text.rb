# frozen_string_literal: true

module DiffViewer
  class Text < Base
    include Simple
    include ServerSide

    self.partial_name = 'text'
    self.binary = false

    # Since the text diff viewer doesn't render the old and new blobs in full,
    # we only need the limits related to the actual size of the diff which are
    # already enforced in Gitlab::Diff::File.
    self.collapse_limit = nil
    self.size_limit = nil
  end
end
