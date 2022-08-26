# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    # Increment this number to invalidate cached HTML from Markdown documents.
    # Even when reverting an MR, we should increment this because we only
    # persist the cache when the new version is higher.
    #
    # Changing this value puts strain on the database, as every row with
    # cached markdown needs to be updated. As a result, avoid changing
    # this if the change to the renderer output is a new feature or a
    # minor bug fix.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/330313
    CACHE_COMMONMARK_VERSION       = 32
    CACHE_COMMONMARK_VERSION_START = 10

    BaseError = Class.new(StandardError)
    UnsupportedClassError = Class.new(BaseError)
  end
end
