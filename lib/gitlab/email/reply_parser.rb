# frozen_string_literal: true

# Inspired in great part by Discourse's Email::Receiver
module Gitlab
  module Email
    class ReplyParser
      attr_accessor :message, :allow_only_quotes

      def initialize(message, trim_reply: true, append_reply: false, allow_only_quotes: false)
        @message = message
        @trim_reply = trim_reply
        @append_reply = append_reply
        @allow_only_quotes = allow_only_quotes
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
        #
        # If allow_only_quotes is true a message where all lines starts with ">" is allowed.
        # This could happen if an email has an empty quote, forwarded without any new content.
        return "" if body.lines.all? do |l|
          l.strip.empty? || (!allow_only_quotes && l.start_with?('>'))
        end

        encoded_body = force_utf8(body.force_encoding(encoding))
        return encoded_body unless @append_reply

        [encoded_body, force_utf8(stripped_text.force_encoding(encoding))]
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
        if %r{(Content\-Type\:|multipart/alternative|text/plain)}.match?(decoded)
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
          # A part of a multi-part may have a different encoding. Its encoding
          # is denoted in its header. For example:
          #
          # ```
          # ------=_Part_2192_32400445.1115745999735
          # Content-Type: text/plain; charset=ISO-8859-1
          # Content-Transfer-Encoding: 7bit
          #
          # Plain email.
          # ```
          object.body.decoded.force_encoding(object.charset.gsub(/utf8/i, "UTF-8")).encode("UTF-8").to_s
        else
          object.body.to_s
        end
      rescue StandardError
        nil
      end

      def force_utf8(str)
        Gitlab::EncodingHelper.encode_utf8(str).to_s
      end
    end
  end
end
