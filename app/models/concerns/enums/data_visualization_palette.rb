# frozen_string_literal: true

module Enums
  # These color palettes are part of the Pajamas Design System.
  # See https://design.gitlab.com/data-visualization/color/#categorical-data
  module DataVisualizationPalette
    def self.colors
      {
        blue: 0,
        orange: 1,
        aqua: 2,
        green: 3,
        magenta: 4
      }
    end

    def self.weights
      {
        '50' => 0,
        '100' => 1,
        '200' => 2,
        '300' => 3,
        '400' => 4,
        '500' => 5,
        '600' => 6,
        '700' => 7,
        '800' => 8,
        '900' => 9,
        '950' => 10
      }
    end
  end
end
