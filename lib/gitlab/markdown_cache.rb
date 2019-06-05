# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    # Increment this number every time the renderer changes its output
    CACHE_COMMONMARK_VERSION_START  = 10
    CACHE_COMMONMARK_VERSION        = 16

    BaseError = Class.new(StandardError)
    UnsupportedClassError = Class.new(BaseError)
  end
end
