# frozen_string_literal: true

module Banzai
  module ColorParser
    ALPHA = /0(?:\.\d+)?|\.\d+|1(?:\.0+)?/.freeze # 0.0..1.0
    PERCENTS = /(?:\d{1,2}|100)%/.freeze # 00%..100%
    ALPHA_CHANNEL = /(?:,\s*(?:#{ALPHA}|#{PERCENTS}))?/.freeze
    BITS = /\d{1,2}|1\d\d|2(?:[0-4]\d|5[0-5])/.freeze # 00..255
    DEGS = /-?\d+(?:deg)?/i.freeze # [-]digits[deg]
    RADS = /-?(?:\d+(?:\.\d+)?|\.\d+)rad/i.freeze # [-](digits[.digits] OR .digits)rad
    HEX_FORMAT = /\#(?:\h{3}|\h{4}|\h{6}|\h{8})/.freeze
    RGB_FORMAT = %r{
      (?:rgba?
        \(
          (?:
            (?:(?:#{BITS},\s*){2}#{BITS})
            |
            (?:(?:#{PERCENTS},\s*){2}#{PERCENTS})
          )
          #{ALPHA_CHANNEL}
        \)
      )
    }xi.freeze
    HSL_FORMAT = %r{
      (?:hsla?
        \(
          (?:#{DEGS}|#{RADS}),\s*#{PERCENTS},\s*#{PERCENTS}
          #{ALPHA_CHANNEL}
        \)
      )
    }xi.freeze

    FORMATS = [HEX_FORMAT, RGB_FORMAT, HSL_FORMAT].freeze

    COLOR_FORMAT = /\A(#{Regexp.union(FORMATS)})\z/ix.freeze

    # Public: Analyzes whether the String is a color code.
    #
    # text - The String to be parsed.
    #
    # Returns the recognized color String or nil if none was found.
    def self.parse(text)
      text if COLOR_FORMAT =~ text
    end
  end
end
