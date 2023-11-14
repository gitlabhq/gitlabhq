# frozen_string_literal: true

module Mutations
  module Ci
    module Catalog
      module Resources
        class Base < BaseMutation
          argument :project_path, GraphQL::Types::ID,
            required: true,
            description: 'Project path belonging to the catalog resource.'

          def find_object(project_path:)
            Project.find_by_full_path(project_path)
          end
        end
      end
    end
  end
end
