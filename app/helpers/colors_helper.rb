# frozen_string_literal: true

module ColorsHelper
  HEX_COLOR_PATTERN = /\A\#(?:[0-9A-Fa-f]{3}){1,2}\Z/.freeze

  def hex_color_to_rgb_array(hex_color)
    raise ArgumentError, "invalid hex color `#{hex_color}`" unless hex_color =~ HEX_COLOR_PATTERN

    hex_color.length == 7 ? hex_color[1, 7].scan(/.{2}/).map(&:hex) : hex_color[1, 4].scan(/./).map { |v| (v * 2).hex }
  end

  def rgb_array_to_hex_color(rgb_array)
    raise ArgumentError, "invalid RGB array `#{rgb_array}`" unless rgb_array_valid?(rgb_array)

    "##{rgb_array.map{ "%02x" % _1 }.join}"
  end

  private

  def rgb_array_valid?(rgb_array)
    rgb_array.is_a?(Array) && rgb_array.length == 3 && rgb_array.all?{ _1 >= 0 && _1 <= 255 }
  end
end
