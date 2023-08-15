# frozen_string_literal: true

module Types
  module Notes
    class PositionTypeEnum < BaseEnum
      graphql_name 'DiffPositionType'
      description 'Type of file the position refers to'

      value 'text', description: "Text file."
      value 'image', description: "An image."
      value 'file', description: "Unknown file type."
    end
  end
end
