# Patch Strings to enable detect_encoding! on views
require 'charlock_holmes/string'

module Gitlabhq
  module Encode 
    extend self

    def utf8 message
      return nil unless message

      encoding = detect_encoding(message)
      if encoding
        CharlockHolmes::Converter.convert(message, encoding, 'UTF-8')
      else
        message
      end.force_encoding("utf-8")
    # Prevent app from crash cause of 
    # encoding errors
    rescue
      ""
    end

    def detect_encoding message
      return nil unless message

      hash = CharlockHolmes::EncodingDetector.detect(message) rescue {}
      return hash[:encoding] ? hash[:encoding] : nil
    end
  end
end
