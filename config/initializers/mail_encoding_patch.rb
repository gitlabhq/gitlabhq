# frozen_string_literal: true

# Monkey patch mail 2.8.1 to fix quoted-printable issues with newlines
# The issues upstream invalidate SMIME signatures under some conditions
# This was working properly in 2.6.6
#
# See https://gitlab.com/gitlab-org/gitlab/issues/197386
# See https://github.com/mikel/mail/issues/1190

module Mail
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
            # Sometimes, the decoded string is frozen. Encoders in
            # Mail::Encodings behave differently in this case. Unlike the
            # original implementation which does not modify this string, we
            # enforce the encoding below. That may lead to FrozenError.
            # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/364619
            decoded = decoded.dup if decoded.frozen?

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
