# frozen_string_literal: true

module Types
  class RefTypeEnum < BaseEnum
    graphql_name 'RefType'
    description 'Type of ref'

    value 'HEADS', description: 'Ref type for branches.', value: 'heads'
    value 'TAGS', description: 'Ref type for tags.', value: 'tags'
  end
end
