# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    # Increment this number every time the renderer changes its output.
    # Changing this value puts strain on the database, as every row with
    # cached markdown needs to be updated. As a result, this line should
    # not be changed.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/330313
    CACHE_COMMONMARK_VERSION        = 28
    CACHE_COMMONMARK_VERSION_START  = 10

    BaseError = Class.new(StandardError)
    UnsupportedClassError = Class.new(BaseError)
  end
end
