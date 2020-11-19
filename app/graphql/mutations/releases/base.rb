# frozen_string_literal: true

module Mutations
  module Releases
    class Base < BaseMutation
      include ResolvesProject

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Full path of the project the release is associated with'

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end
    end
  end
end
