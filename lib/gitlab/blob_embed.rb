# frozen_string_literal: true

module Gitlab
  module BlobEmbed
    # Matches a fully-qualified blob permalink URL on this instance, capturing
    # the parts needed to locate the blob and the range of lines to show.
    #
    # Discard query string, if any: permalinks copied from the UI might have
    # `blame`, `page` or `plain` parameters before the anchor.
    def self.permalink_pattern
      @permalink_pattern ||= %r{
        \A#{Regexp.escape(Gitlab.config.gitlab.url)}/
        (?<namespace>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})/
        (?<project>#{Gitlab::PathRegex::PROJECT_PATH_FORMAT_REGEX})
        /-/blob/
        (?<commit>\h{40})
        /(?<blob_path>[^\#?\s]+)
        (?:\?[^\#\s]*)?
        (?<anchor>\#\S*)?
      }x
    end
  end
end
