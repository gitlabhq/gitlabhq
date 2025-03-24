# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Conan
        class RecipeRevision < Grape::Entity
          expose :revision, documentation: {
            type: String,
            desc: 'The revision hash of the Conan recipe',
            example: '75151329520e7685dcf5da49ded2fec0'
          }

          expose :created_at, as: :time, documentation: {
            type: String,
            desc: 'The UTC timestamp when the revision was created',
            example: '2024-12-17T09:16:40.334Z'
          }
        end
      end
    end
  end
end
