# frozen_string_literal: true

module BlobViewer
  module Static
    extend ActiveSupport::Concern

    included do
      self.load_async = false
    end

    # We can always render a static viewer, even if the blob is too large.
    def render_error
      nil
    end
  end
end
