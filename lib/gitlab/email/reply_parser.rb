# frozen_string_literal: true

# Inspired in great part by Discourse's Email::Receiver
module Gitlab
  module Email
    class ReplyParser
      attr_accessor :message

      def initialize(message, trim_reply: true, append_reply: false)
        @message = message
        @trim_reply = trim_reply
        @append_reply = append_reply
      end

      def execute
        body = select_body(message)

        encoding = body.encoding
        body, stripped_text = EmailReplyTrimmer.trim(body, @append_reply) if @trim_reply
        return '' unless body

        # not using /\s+$/ here because that deletes empty lines
        body = body.gsub(/[ \t]$/, '')

        # NOTE: We currently don't support empty quotes.
        # EmailReplyTrimmer allows this as a special case,
        # so we detect it manually here.
        return "" if body.lines.all? { |l| l.strip.empty? || l.start_with?('>') }

        encoded_body = body.force_encoding(encoding).encode("UTF-8")
        return encoded_body unless @append_reply

        [encoded_body, stripped_text.force_encoding(encoding).encode("UTF-8")]
      end

      private

      def select_body(message)
        part =
          if message.multipart?
            message.text_part || message.html_part || message
          else
            message
          end

        decoded = fix_charset(part)

        return "" unless decoded

        # Certain trigger phrases that means we didn't parse correctly
        if decoded =~ %r{(Content\-Type\:|multipart/alternative|text/plain)}
          return ""
        end

        if (part.content_type || '').include? 'text/html'
          HTMLParser.parse_reply(decoded)
        else
          decoded
        end
      end

      # Force encoding to UTF-8 on a Mail::Message or Mail::Part
      def fix_charset(object)
        return if object.nil?

        if object.charset
          object.body.decoded.force_encoding(object.charset.gsub(/utf8/i, "UTF-8")).encode("UTF-8").to_s
        else
          object.body.to_s
        end
      rescue StandardError
        nil
      end
    end
  end
end
