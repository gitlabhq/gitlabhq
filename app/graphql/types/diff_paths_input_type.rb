# frozen_string_literal: true

module Types
  class DiffPathsInputType < BaseInputObject
    argument :old_path, GraphQL::Types::String, required: false,
              description: 'Path of the file on the start SHA.'
    argument :new_path, GraphQL::Types::String, required: false,
              description: 'Path of the file on the HEAD SHA.'
  end
end
