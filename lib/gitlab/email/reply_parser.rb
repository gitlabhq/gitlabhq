# Inspired in great part by Discourse's Email::Receiver
# https://github.com/discourse/discourse/blob/e92f5e4fbf04a88d37dc5069917090abf6c07dec/lib/email/receiver.rb
module Gitlab
  module Email
    class ReplyParser
      attr_accessor :mail

      def initialize(mail)
        @mail = mail
      end

      def execute
        text = nil
        html = nil

        if mail.multipart?
          text = fix_charset(mail.text_part)
          html = fix_charset(mail.html_part)
        elsif mail.content_type.to_s['text/html']
          html = fix_charset(mail)
        else
          text = fix_charset(mail)
        end

        if html.present?
          cleaned_html = Email::HtmlCleaner.new(html).output_html
          EmailReplyTrimmer.trim(cleaned_html)
        elsif text.present?
          EmailReplyTrimmer.trim(text)
        else
          ''
        end
      end

      private

      # copied from https://github.com/discourse/discourse/blob/e92f5e4fbf04a88d37dc5069917090abf6c07dec/lib/email/receiver.rb
      def fix_charset(mail_part)
        return nil if mail_part.blank? || mail_part.body.blank?

        string = mail_part.body.decoded rescue nil

        return nil if string.blank?

        # common encodings
        encodings = ["UTF-8", "ISO-8859-1"]
        encodings.unshift(mail_part.charset) if mail_part.charset.present?

        encodings.uniq.each do |encoding|
          fixed = try_to_encode(string, encoding)
          return fixed if fixed.present?
        end

        nil
      end

      # copied from https://github.com/discourse/discourse/blob/e92f5e4fbf04a88d37dc5069917090abf6c07dec/lib/email/receiver.rb
      def try_to_encode(string, encoding)
        encoded = string.encode("UTF-8", encoding)
        encoded.present? && encoded.valid_encoding? ? encoded : nil
      rescue Encoding::InvalidByteSequenceError,
             Encoding::UndefinedConversionError,
             Encoding::ConverterNotFoundError
        nil
      end
    end
  end
end
