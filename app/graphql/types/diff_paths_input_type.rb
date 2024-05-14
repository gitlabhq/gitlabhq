# frozen_string_literal: true

module Types
  class DiffPathsInputType < BaseInputObject
    argument :new_path, GraphQL::Types::String, required: false,
      description: 'Path of the file on the HEAD SHA.'
    argument :old_path, GraphQL::Types::String, required: false,
      description: 'Path of the file on the start SHA.'
  end
end
