# frozen_string_literal: true

module Types
  module BlobViewers
    class TypeEnum < BaseEnum
      graphql_name 'BlobViewersType'
      description 'Types of blob viewers'

      value 'rich', value: :rich, description: 'Rich blob viewers type.'
      value 'simple', value: :simple, description: 'Simple blob viewers type.'
      value 'auxiliary', value: :auxiliary, description: 'Auxiliary blob viewers type.'
    end
  end
end
