# frozen_string_literal: true

module API
  module Entities
    module ConanPackage
      class ConanRecipeSnapshot < Grape::Entity
        expose :recipe_snapshot, merge: true
      end
    end
  end
end
