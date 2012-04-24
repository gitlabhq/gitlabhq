module Gitlabhq
  module Encode 
    extend self

    def utf8 message
      hash = CharlockHolmes::EncodingDetector.detect(message) rescue {}
      if hash[:encoding]
        CharlockHolmes::Converter.convert(message, hash[:encoding], 'UTF-8')
      else
        message
      end.force_encoding("utf-8")
    end
  end
end
