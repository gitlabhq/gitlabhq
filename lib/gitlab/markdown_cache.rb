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
    CACHE_COMMONMARK_VERSION       = 33
    CACHE_COMMONMARK_VERSION_START = 10
    CACHE_COMMONMARK_VERSION_SHIFTED = CACHE_COMMONMARK_VERSION << 16

    BaseError = Class.new(StandardError)
    UnsupportedClassError = Class.new(BaseError)

    # We could be called by a method that is inside the Gitlab::CurrentSettings
    # object. In this case we need to pass in the local_markdown_version in order
    # to avoid an infinite loop. See usaage in `app/models/concerns/cache_markdown_field.rb`
    # Otherwise pass in `nil`
    def self.latest_cached_markdown_version(local_version:)
      local_version ||= Gitlab::CurrentSettings.current_application_settings.local_markdown_version

      CACHE_COMMONMARK_VERSION_SHIFTED | local_version
    end
  end
end
