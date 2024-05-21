# frozen_string_literal: true

module API
  module Entities
    module ConanPackage
      class ConanRecipeSnapshot < Grape::Entity
        expose :recipe_snapshot, merge: true,
          documentation: {
            type: 'object',
            example: '{ "conan_sources.tgz": "eadf19b33f4c3c7e113faabf26e76277" }'
          }
      end
    end
  end
end
