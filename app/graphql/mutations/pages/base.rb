# frozen_string_literal: true

module Mutations
  module Pages
    class Base < BaseMutation
      include FindsProject

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project.'
    end
  end
end
