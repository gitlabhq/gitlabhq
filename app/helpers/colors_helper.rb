# frozen_string_literal: true

module ColorsHelper
  HEX_COLOR_PATTERN = /\A\#(?:[0-9A-Fa-f]{3}){1,2}\Z/

  def hex_color_to_rgb_array(hex_color)
    unless hex_color.is_a?(String) && HEX_COLOR_PATTERN.match?(hex_color)
      raise ArgumentError, "invalid hex color `#{hex_color}`"
    end

    hex_color.length == 7 ? hex_color[1, 7].scan(/.{2}/).map(&:hex) : hex_color[1, 4].scan(/./).map { |v| (v * 2).hex }
  end
end
