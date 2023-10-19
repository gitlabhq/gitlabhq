# frozen_string_literal: true

module Gitlab
  class Color
    PATTERN = /\A\#(?:[0-9A-Fa-f]{3}){1,2}\Z/

    def initialize(value)
      @value = value&.strip&.freeze
    end

    module Constants
      DARK = Color.new('#1F1E24')
      LIGHT = Color.new('#FFFFFF')

      COLOR_NAME_TO_HEX = {
        black: '#000000',
        silver: '#C0C0C0',
        gray: '#808080',
        white: '#FFFFFF',
        maroon: '#800000',
        red: '#FF0000',
        purple: '#800080',
        fuchsia: '#FF00FF',
        green: '#008000',
        lime: '#00FF00',
        olive: '#808000',
        yellow: '#FFFF00',
        navy: '#000080',
        blue: '#0000FF',
        teal: '#008080',
        aqua: '#00FFFF',
        orange: '#FFA500',
        aliceblue: '#F0F8FF',
        antiquewhite: '#FAEBD7',
        aquamarine: '#7FFFD4',
        azure: '#F0FFFF',
        beige: '#F5F5DC',
        bisque: '#FFE4C4',
        blanchedalmond: '#FFEBCD',
        blueviolet: '#8A2BE2',
        brown: '#A52A2A',
        burlywood: '#DEB887',
        cadetblue: '#5F9EA0',
        chartreuse: '#7FFF00',
        chocolate: '#D2691E',
        coral: '#FF7F50',
        cornflowerblue: '#6495ED',
        cornsilk: '#FFF8DC',
        crimson: '#DC143C',
        darkblue: '#00008B',
        darkcyan: '#008B8B',
        darkgoldenrod: '#B8860B',
        darkgray: '#A9A9A9',
        darkgreen: '#006400',
        darkgrey: '#A9A9A9',
        darkkhaki: '#BDB76B',
        darkmagenta: '#8B008B',
        darkolivegreen: '#556B2F',
        darkorange: '#FF8C00',
        darkorchid: '#9932CC',
        darkred: '#8B0000',
        darksalmon: '#E9967A',
        darkseagreen: '#8FBC8F',
        darkslateblue: '#483D8B',
        darkslategray: '#2F4F4F',
        darkslategrey: '#2F4F4F',
        darkturquoise: '#00CED1',
        darkviolet: '#9400D3',
        deeppink: '#FF1493',
        deepskyblue: '#00BFFF',
        dimgray: '#696969',
        dimgrey: '#696969',
        dodgerblue: '#1E90FF',
        firebrick: '#B22222',
        floralwhite: '#FFFAF0',
        forestgreen: '#228B22',
        gainsboro: '#DCDCDC',
        ghostwhite: '#F8F8FF',
        gold: '#FFD700',
        goldenrod: '#DAA520',
        greenyellow: '#ADFF2F',
        grey: '#808080',
        honeydew: '#F0FFF0',
        hotpink: '#FF69B4',
        indianred: '#CD5C5C',
        indigo: '#4B0082',
        ivory: '#FFFFF0',
        khaki: '#F0E68C',
        lavender: '#E6E6FA',
        lavenderblush: '#FFF0F5',
        lawngreen: '#7CFC00',
        lemonchiffon: '#FFFACD',
        lightblue: '#ADD8E6',
        lightcoral: '#F08080',
        lightcyan: '#E0FFFF',
        lightgoldenrodyellow: '#FAFAD2',
        lightgray: '#D3D3D3',
        lightgreen: '#90EE90',
        lightgrey: '#D3D3D3',
        lightpink: '#FFB6C1',
        lightsalmon: '#FFA07A',
        lightseagreen: '#20B2AA',
        lightskyblue: '#87CEFA',
        lightslategray: '#778899',
        lightslategrey: '#778899',
        lightsteelblue: '#B0C4DE',
        lightyellow: '#FFFFE0',
        limegreen: '#32CD32',
        linen: '#FAF0E6',
        mediumaquamarine: '#66CDAA',
        mediumblue: '#0000CD',
        mediumorchid: '#BA55D3',
        mediumpurple: '#9370DB',
        mediumseagreen: '#3CB371',
        mediumslateblue: '#7B68EE',
        mediumspringgreen: '#00FA9A',
        mediumturquoise: '#48D1CC',
        mediumvioletred: '#C71585',
        midnightblue: '#191970',
        mintcream: '#F5FFFA',
        mistyrose: '#FFE4E1',
        moccasin: '#FFE4B5',
        navajowhite: '#FFDEAD',
        oldlace: '#FDF5E6',
        olivedrab: '#6B8E23',
        orangered: '#FF4500',
        orchid: '#DA70D6',
        palegoldenrod: '#EEE8AA',
        palegreen: '#98FB98',
        paleturquoise: '#AFEEEE',
        palevioletred: '#DB7093',
        papayawhip: '#FFEFD5',
        peachpuff: '#FFDAB9',
        peru: '#CD853F',
        pink: '#FFC0CB',
        plum: '#DDA0DD',
        powderblue: '#B0E0E6',
        rosybrown: '#BC8F8F',
        royalblue: '#4169E1',
        saddlebrown: '#8B4513',
        salmon: '#FA8072',
        sandybrown: '#F4A460',
        seagreen: '#2E8B57',
        seashell: '#FFF5EE',
        sienna: '#A0522D',
        skyblue: '#87CEEB',
        slateblue: '#6A5ACD',
        slategray: '#708090',
        slategrey: '#708090',
        snow: '#FFFAFA',
        springgreen: '#00FF7F',
        steelblue: '#4682B4',
        tan: '#D2B48C',
        thistle: '#D8BFD8',
        tomato: '#FF6347',
        turquoise: '#40E0D0',
        violet: '#EE82EE',
        wheat: '#F5DEB3',
        whitesmoke: '#F5F5F5',
        yellowgreen: '#9ACD32',
        rebeccapurple: '#663399'
      }.stringify_keys.transform_values { Color.new(_1) }.freeze
    end

    def self.of(color)
      raise ArgumentError, 'No color spec' unless color
      return color if color.is_a?(self)

      color = color.to_s.strip
      Constants::COLOR_NAME_TO_HEX[color.downcase] || new(color)
    end

    # Generate a hex color based on hex-encoded value
    def self.color_for(value)
      Color.new("##{Digest::SHA256.hexdigest(value.to_s)[0..5]}")
    end

    def to_s
      @value.to_s
    end

    def as_json(_options = nil)
      to_s
    end

    def eql(other)
      return false unless other.is_a?(self.class)

      to_s == other.to_s
    end
    alias_method :==, :eql

    def valid?
      PATTERN.match?(@value)
    end

    # Implementation should match
    # https://gitlab.com/gitlab-org/gitlab-ui/-/blob/6245128c7256e3d8db164b92e9580c79d47e9183/src/utils/utils.js#L52-55
    def to_srgb(value)
      normalized = value / 255.0
      normalized <= 0.03928 ? normalized / 12.92 : ((normalized + 0.055) / 1.055)**2.4
    end

    # Implementation should match
    # https://gitlab.com/gitlab-org/gitlab-ui/-/blob/6245128c7256e3d8db164b92e9580c79d47e9183/src/utils/utils.js#L57-64
    def relative_luminance(rgb)
      # WCAG 2.1 formula: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
      # -
      # WCAG 3.0 will use APAC
      # Using APAC would be the ultimate goal, but was dismissed by engineering as of now
      # See https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/3418#note_1370107090
      (0.2126 * to_srgb(rgb[0])) + (0.7152 * to_srgb(rgb[1])) + (0.0722 * to_srgb(rgb[2]))
    end

    # Implementation should match
    # https://gitlab.com/gitlab-org/gitlab-ui/-/blob/6245128c7256e3d8db164b92e9580c79d47e9183/src/utils/utils.js#L66-91
    def light?
      return false unless valid?

      luminance = relative_luminance(rgb)
      light_luminance = relative_luminance([255, 255, 255])
      dark_luminance = relative_luminance([31, 30, 36])

      contrast_light = (light_luminance + 0.05) / (luminance + 0.05)
      contrast_dark = (luminance + 0.05) / (dark_luminance + 0.05)

      # Using a threshold contrast of 2.4 instead of 3
      # as this will solve weird color combinations in the mid tones
      #
      # Note that this is the negated condition from GitLab UI,
      # because the GitLab UI implementation returns the text color,
      # while this defines whether a background color is light
      !(contrast_light >= 2.4 || contrast_light > contrast_dark)
    end

    def luminosity
      return :light if light?

      :dark
    end

    def contrast
      return Constants::DARK if light?

      Constants::LIGHT
    end

    private

    def rgb
      return [] unless valid?

      @rgb ||= if @value.length == 4
                 @value[1, 4].scan(/./).map { |v| (v * 2).hex }
               else
                 @value[1, 7].scan(/.{2}/).map(&:hex)
               end
    end
  end
end
