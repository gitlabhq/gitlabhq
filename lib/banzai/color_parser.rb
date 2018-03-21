module Banzai
  module ColorParser
    ALPHA = /0(?:\.\d+)?|\.\d+|1(?:\.0+)?/ # 0.0..1.0
    PERCENTS = /(?:\d{1,2}|100)%/ # 00%..100%
    ALPHA_CHANNEL = /(?:,\s*(?:#{ALPHA}|#{PERCENTS}))?/
    BITS = /\d{1,2}|1\d\d|2(?:[0-4]\d|5[0-5])/ # 00..255
    DEGS = /-?\d+(?:deg)?/i # [-]digits[deg]
    RADS = /-?(?:\d+(?:\.\d+)?|\.\d+)rad/i # [-](digits[.digits] OR .digits)rad
    HEX_FORMAT = /\#(?:\h{3}|\h{4}|\h{6}|\h{8})/
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
    }xi
    HSL_FORMAT = %r{
      (?:hsla?
        \(
          (?:#{DEGS}|#{RADS}),\s*#{PERCENTS},\s*#{PERCENTS}
          #{ALPHA_CHANNEL}
        \)
      )
    }xi

    FORMATS = [HEX_FORMAT, RGB_FORMAT, HSL_FORMAT].freeze

    COLOR_FORMAT = /\A(#{Regexp.union(FORMATS)})\z/ix

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
