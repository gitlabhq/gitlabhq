# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Conan
        class RecipeRevisions < Grape::Entity
          MAX_REVISIONS_COUNT = 1000

          expose :conan_recipe, as: :reference, documentation: {
            type: String,
            desc: 'The Conan package reference',
            example: 'packageTest/1.2.3@gitlab-org+conan/stable'
          }

          expose :conan_recipe_revisions, as: :revisions, using:
          ::API::Entities::Packages::Conan::RecipeRevision, documentation: {
            type: Array,
            desc: 'List of recipe revisions',
            is_array: true
          } do |package|
            package.conan_recipe_revisions.order_by_id_desc.limit(MAX_REVISIONS_COUNT)
          end
        end
      end
    end
  end
end
