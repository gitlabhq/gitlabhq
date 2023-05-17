# frozen_string_literal: true

module Types
  class RelativePositionTypeEnum < BaseEnum
    graphql_name 'RelativePositionType'
    description 'The position to which the object should be moved'

    value 'BEFORE', 'Object is moved before an adjacent object.'
    value 'AFTER', 'Object is moved after an adjacent object.'
  end
end
