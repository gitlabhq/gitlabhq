# frozen_string_literal: true

require_relative 'base'

module Gitlab
  module EmailHandler
    module Matchers
      # Mirrors Gitlab::Email::Handler::UnsubscribeHandler.
      #   incoming+<reply_key>-unsubscribe@incoming.gitlab.com
      #   incoming+<reply_key>+unsubscribe@incoming.gitlab.com (legacy)
      class Unsubscribe < Base
        HANDLER_REGEX_FOR = ->(suffix) {
          /\A(?<reply_token>#{ReplyKey::FULL_REPLY_KEY_REGEX})#{Regexp.escape(suffix)}\z/
        }.freeze
        HANDLER_REGEX = HANDLER_REGEX_FOR.call(ReplyKey::UNSUBSCRIBE_SUFFIX).freeze
        HANDLER_REGEX_LEGACY = HANDLER_REGEX_FOR.call(ReplyKey::UNSUBSCRIBE_SUFFIX_LEGACY).freeze

        def match(mail_key)
          key = mail_key.to_s
          matched = HANDLER_REGEX.match(key) || HANDLER_REGEX_LEGACY.match(key)
          return unless matched

          identification(
            reply_token: matched[:reply_token],
            reply_key: matched[:reply_key],
            namespace_id: matched[:namespace_id],
            legacy_key: matched[:legacy_key]
          )
        end

        def handler_name
          :unsubscribe
        end
      end
    end
  end
end
