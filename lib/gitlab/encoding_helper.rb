module Gitlab
  module EncodingHelper
    extend self

    # This threshold is carefully tweaked to prevent usage of encodings detected
    # by CharlockHolmes with low confidence. If CharlockHolmes confidence is low,
    # we're better off sticking with utf8 encoding.
    # Reason: git diff can return strings with invalid utf8 byte sequences if it
    # truncates a diff in the middle of a multibyte character. In this case
    # CharlockHolmes will try to guess the encoding and will likely suggest an
    # obscure encoding with low confidence.
    # There is a lot more info with this merge request:
    # https://gitlab.com/gitlab-org/gitlab_git/merge_requests/77#note_4754193
    ENCODING_CONFIDENCE_THRESHOLD = 40

    def encode!(message)
      return nil unless message.respond_to? :force_encoding

      # if message is utf-8 encoding, just return it
      message.force_encoding("UTF-8")
      return message if message.valid_encoding?

      # return message if message type is binary
      detect = CharlockHolmes::EncodingDetector.detect(message)
      return message.force_encoding("BINARY") if detect && detect[:type] == :binary

      # force detected encoding if we have sufficient confidence.
      if detect && detect[:encoding] && detect[:confidence] > ENCODING_CONFIDENCE_THRESHOLD
        message.force_encoding(detect[:encoding])
      end

      # encode and clean the bad chars
      message.replace clean(message)
    rescue
      encoding = detect ? detect[:encoding] : "unknown"
      "--broken encoding: #{encoding}"
    end

    def encode_utf8(message)
      detect = CharlockHolmes::EncodingDetector.detect(message)
      if detect && detect[:encoding]
        begin
          CharlockHolmes::Converter.convert(message, detect[:encoding], 'UTF-8')
        rescue ArgumentError => e
          Rails.logger.warn("Ignoring error converting #{detect[:encoding]} into UTF8: #{e.message}")

          ''
        end
      else
        clean(message)
      end
    end

    private

    def clean(message)
      message.encode("UTF-16BE", undef: :replace, invalid: :replace, replace: "")
        .encode("UTF-8")
        .gsub("\0".encode("UTF-8"), "")
    end
  end
end
