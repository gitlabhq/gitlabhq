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
    ENCODING_CONFIDENCE_THRESHOLD = 50

    def encode!(message)
      message = force_encode_utf8(message)
      return message if message.valid_encoding?

      # return message if message type is binary
      detect = CharlockHolmes::EncodingDetector.detect(message)
      return message.force_encoding("BINARY") if detect_binary?(message, detect)

      if detect && detect[:encoding] && detect[:confidence] > ENCODING_CONFIDENCE_THRESHOLD
        # force detected encoding if we have sufficient confidence.
        message.force_encoding(detect[:encoding])
      end

      # encode and clean the bad chars
      message.replace clean(message)
    rescue ArgumentError => e
      return unless e.message.include?('unknown encoding name')

      encoding = detect ? detect[:encoding] : "unknown"
      "--broken encoding: #{encoding}"
    end

    def detect_binary?(data, detect = nil)
      detect ||= CharlockHolmes::EncodingDetector.detect(data)
      detect && detect[:type] == :binary && detect[:confidence] == 100
    end

    def detect_libgit2_binary?(data)
      # EncodingDetector checks the first 1024 * 1024 bytes for NUL byte, libgit2 checks
      # only the first 8000 (https://github.com/libgit2/libgit2/blob/2ed855a9e8f9af211e7274021c2264e600c0f86b/src/filter.h#L15),
      # which is what we use below to keep a consistent behavior.
      detect = CharlockHolmes::EncodingDetector.new(8000).detect(data)
      detect && detect[:type] == :binary
    end

    def encode_utf8(message)
      message = force_encode_utf8(message)
      return message if message.valid_encoding?

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
    rescue ArgumentError
      return nil
    end

    def encode_binary(s)
      return "" if s.nil?

      s.dup.force_encoding(Encoding::ASCII_8BIT)
    end

    def binary_stringio(s)
      StringIO.new(s || '').tap { |io| io.set_encoding(Encoding::ASCII_8BIT) }
    end

    private

    def force_encode_utf8(message)
      raise ArgumentError unless message.respond_to?(:force_encoding)
      return message if message.encoding == Encoding::UTF_8 && message.valid_encoding?

      message = message.dup if message.respond_to?(:frozen?) && message.frozen?

      message.force_encoding("UTF-8")
    end

    def clean(message)
      message.encode("UTF-16BE", undef: :replace, invalid: :replace, replace: "")
        .encode("UTF-8")
        .gsub("\0".encode("UTF-8"), "")
    end
  end
end
