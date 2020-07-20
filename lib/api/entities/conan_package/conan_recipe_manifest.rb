# frozen_string_literal: true

module API
  module Entities
    module ConanPackage
      class ConanRecipeManifest < Grape::Entity
        expose :recipe_urls, merge: true
      end
    end
  end
end
