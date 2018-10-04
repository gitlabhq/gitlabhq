# frozen_string_literal: true

module DiffViewer
  module Static
    extend ActiveSupport::Concern

    # We can always render a static viewer, even if the diff is too large.
    def render_error
      nil
    end
  end
end
