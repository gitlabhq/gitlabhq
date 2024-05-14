# frozen_string_literal: true

module Mutations
  module Releases
    class Base < BaseMutation
      include FindsProject

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project the release is associated with.'
    end
  end
end
