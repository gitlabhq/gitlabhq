# frozen_string_literal: true

module Types
  module DataVisualizationPalette
    class ColorEnum < BaseEnum
      graphql_name 'DataVisualizationColorEnum'
      description 'Color of the data visualization palette'

      Enums::DataVisualizationPalette.colors.keys.each do |unit|
        value unit.upcase, value: unit, description: "#{unit.to_s.titleize} color"
      end
    end
  end
end
