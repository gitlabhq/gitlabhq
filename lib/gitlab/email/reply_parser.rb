# Inspired in great part by Discourse's Email::Receiver
module Gitlab
  module Email
    class ReplyParser
      attr_accessor :message

      def initialize(message)
        @message = message
      end

      def execute
        body = select_body(message)

        encoding = body.encoding

        body = discourse_email_trimmer(body)

        body = EmailReplyParser.parse_reply(body)

        body.force_encoding(encoding).encode("UTF-8")
      end

      private

      def select_body(message)
        text    = message.text_part if message.multipart?
        text  ||= message           if message.content_type !~ /text\/html/

        return "" unless text

        text = fix_charset(text)

        # Certain trigger phrases that means we didn't parse correctly
        if text =~ /(Content\-Type\:|multipart\/alternative|text\/plain)/
          return ""
        end

        text
      end

      # Force encoding to UTF-8 on a Mail::Message or Mail::Part
      def fix_charset(object)
        return nil if object.nil?

        if object.charset
          object.body.decoded.force_encoding(object.charset.gsub(/utf8/i, "UTF-8")).encode("UTF-8").to_s
        else
          object.body.to_s
        end
      rescue
        nil
      end

      REPLYING_HEADER_LABELS = %w(From Sent To Subject Reply To Cc Bcc Date)
      REPLYING_HEADER_REGEX = Regexp.union(REPLYING_HEADER_LABELS.map { |label| "#{label}:" })

      def discourse_email_trimmer(body)
        lines = body.scrub.lines.to_a
        range_end = 0

        lines.each_with_index do |l, idx|
          # This one might be controversial but so many reply lines have years, times and end with a colon.
          # Let's try it and see how well it works.
          break if (l =~ /\d{4}/ && l =~ /\d:\d\d/ && l =~ /\:$/) ||
                   (l =~ /On \w+ \d+,? \d+,?.*wrote:/)

          # Headers on subsequent lines
          break if (0..2).all? { |off| lines[idx+off] =~ REPLYING_HEADER_REGEX }
          # Headers on the same line
          break if REPLYING_HEADER_LABELS.count { |label| l.include?(label) } >= 3

          range_end = idx
        end

        lines[0..range_end].join.strip
      end
    end
  end
end
