# frozen_string_literal: true

module Types
  class DiffPathsInputType < BaseInputObject
    argument :old_path, GraphQL::STRING_TYPE, required: false,
              description: 'The path of the file on the start sha.'
    argument :new_path, GraphQL::STRING_TYPE, required: false,
              description: 'The path of the file on the head sha.'
  end
end
