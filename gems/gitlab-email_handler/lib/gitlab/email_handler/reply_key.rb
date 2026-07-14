# frozen_string_literal: true

module Gitlab
  module EmailHandler
    # Single source of truth for the regular expressions and constants used to
    # parse incoming email keys. These were previously defined inline in
    # `SentNotification` and the email handlers. Keeping them here lets both the
    # GitLab application and the standalone mail_room identification service
    # share the exact same parsing rules.
    module ReplyKey
      REPLY_KEY_BYTE_SIZE = 16
      INTEGER_CONVERT_BASE = 36
      BASE36_REGEX = /[0-9a-z]/
      NAMESPACE_REGEX = /(?:-(?<namespace_id>#{BASE36_REGEX}{1,13}))?/
      # Email reply key is in the form: <base36-partition-id>-<base36-reply-key>-<base36-namespace-id>
      PARTITIONED_REPLY_KEY_REGEX =
        /(?<partition>#{BASE36_REGEX}{1,4})-(?<reply_key>#{BASE36_REGEX}{25})#{NAMESPACE_REGEX}/
      LEGACY_REPLY_KEY_REGEX = /(?<legacy_key>[a-f\d]{32})/
      FULL_REPLY_KEY_REGEX = /(?:(#{LEGACY_REPLY_KEY_REGEX})|(#{PARTITIONED_REPLY_KEY_REGEX}))/

      # Base regex shared by handlers that encode `<project_slug>-<project_id>` in
      # the mail key.
      HANDLER_ACTION_BASE_REGEX = /(?<project_slug>.+)-(?<project_id>\d+)/

      UNSUBSCRIBE_SUFFIX = '-unsubscribe'
      UNSUBSCRIBE_SUFFIX_LEGACY = '+unsubscribe'
    end
  end
end
