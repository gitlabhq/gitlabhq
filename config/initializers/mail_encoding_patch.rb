# frozen_string_literal: true

# Monkey patch mail 2.7.1 to fix quoted-printable issues with newlines
# The issues upstream invalidate SMIME signatures under some conditions
# This was working properly in 2.6.6
#
# See https://gitlab.com/gitlab-org/gitlab/issues/197386
# See https://github.com/mikel/mail/issues/1190

module Mail
  module Encodings
    # PATCH
    # This reverts https://github.com/mikel/mail/pull/1113, which solves some
    # encoding issues with binary attachments encoded in quoted-printable, but
    # unfortunately breaks re-encoding of messages
    class QuotedPrintable < SevenBit
      def self.decode(str)
        ::Mail::Utilities.to_lf str.gsub(/(?:=0D=0A|=0D|=0A)\r\n/, "\r\n").unpack1("M*")
      end

      def self.encode(str)
        ::Mail::Utilities.to_crlf([::Mail::Utilities.to_lf(str)].pack("M"))
      end
    end
  end

  class Body
    def encoded(transfer_encoding = nil, charset = nil)
      # PATCH
      # Use provided parameter charset (from parent Message) if not nil,
      # otherwise use own self.charset
      # Required because the Message potentially has on its headers the charset
      # that needs to be used (e.g. 'Content-Type: text/plain; charset=UTF-8')
      charset = self.charset if charset.nil?

      if multipart?
        self.sort_parts!
        encoded_parts = parts.map { |p| p.encoded }
        ([preamble] + encoded_parts).join(crlf_boundary) + end_boundary + epilogue.to_s
      else
        dec = Mail::Encodings.get_encoding(encoding)
        enc = if Utilities.blank?(transfer_encoding)
                dec
              else
                negotiate_best_encoding(transfer_encoding)
              end

        if dec.nil?
          # Cannot decode, so skip normalization
          raw_source
        else
          # Decode then encode to normalize and allow transforming
          # from base64 to Q-P and vice versa
          decoded = dec.decode(raw_source)

          if defined?(Encoding) && charset && charset != "US-ASCII"
            # PATCH
            # We need to force the encoding: in the case of quoted-printable
            # this will throw an exception otherwise, because `decoded` will have
            # an encoding of BINARY (or its equivalent ASCII-8BIT),
            # coming from QuotedPrintable#decode, and inside it from String#unpack1
            decoded = decoded.force_encoding(charset)
            decoded.force_encoding('BINARY') unless Encoding.find(charset).ascii_compatible?
          end

          enc.encode(decoded)
        end
      end
    end
  end

  class Message
    def encoded
      ready_to_send!
      buffer = header.encoded
      buffer << "\r\n"
      # PATCH
      # Pass the Message charset down to the contained Body, the headers
      # potentially contain the charset needed to be applied
      buffer << body.encoded(content_transfer_encoding, charset)
      buffer
    end
  end
end
