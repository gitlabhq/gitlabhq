# frozen_string_literal: true

module Types
  module Notes
    class PositionTypeEnum < BaseEnum
      graphql_name 'DiffPositionType'
      description 'Type of file the position refers to'

      value 'text', description: "A text file."
      value 'image', description: "An image."
    end
  end
end
