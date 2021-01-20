# frozen_string_literal: true

module Types
  module DataVisualizationPalette
    class WeightEnum < BaseEnum
      graphql_name 'DataVisualizationWeightEnum'
      description 'Weight of the data visualization palette'

      ::Enums::DataVisualizationPalette.weights.keys.each do |unit|
        value "weight_#{unit}".upcase, value: unit, description: "#{unit.to_s.titleize} weight"
      end
    end
  end
end
