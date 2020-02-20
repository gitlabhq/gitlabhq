# frozen_string_literal: true

module Types
  module BlobViewers
    class TypeEnum < BaseEnum
      graphql_name 'BlobViewersType'
      description 'Types of blob viewers'

      value 'rich', value: :rich
      value 'simple', value: :simple
      value 'auxiliary', value: :auxiliary
    end
  end
end
