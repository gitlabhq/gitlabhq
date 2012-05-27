# Patch Strings to enable detect_encoding! on views
require 'charlock_holmes/string'
module Gitlab
  module Encode 
    extend self

    def utf8 message
      return nil unless message

      detect = CharlockHolmes::EncodingDetector.detect(message) rescue {}

      # It's better to default to UTF-8 as sometimes it's wrongly detected as another charset
      if detect[:encoding] && detect[:confidence] == 100
        CharlockHolmes::Converter.convert(message, detect[:encoding], 'UTF-8')
      else
        message
      end.force_encoding("utf-8")

    # Prevent app from crash cause of 
    # encoding errors
    rescue
      "--broken encoding: #{encoding}"
    end

    def detect_encoding message
      return nil unless message

      hash = CharlockHolmes::EncodingDetector.detect(message) rescue {}
      return hash[:encoding] ? hash[:encoding] : nil
    end
  end
end
