# Patch Strings to enable detect_encoding! on views
require 'charlock_holmes/string'
module Gitlab
  module Encode
    extend self

    def utf8 message
      # return nil if message is nil
      return nil unless message

      message.force_encoding("utf-8")
      # return message if message type is binary
      detect = CharlockHolmes::EncodingDetector.detect(message)
      return message if detect[:type] == :binary

      # if message is utf-8 encoding, just return it
      return message if message.valid_encoding?

      # if message is not utf-8 encoding, convert it
      if detect[:encoding]
        message.force_encoding(detect[:encoding])
        message.encode!("utf-8", detect[:encoding], undef: :replace, replace: "", invalid: :replace)
      end

      # ensure message encoding is utf8
      message.valid_encoding? ? message : raise

    # Prevent app from crash cause of encoding errors
    rescue
      encoding = detect ? detect[:encoding] : "unknown"
      "--broken encoding: #{encoding}"
    end

    def detect_encoding message
      return nil unless message

      hash = CharlockHolmes::EncodingDetector.detect(message) rescue {}
      return hash[:encoding] ? hash[:encoding] : nil
    end
  end
end
