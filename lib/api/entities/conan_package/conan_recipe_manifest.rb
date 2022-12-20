# frozen_string_literal: true

module API
  module Entities
    module ConanPackage
      class ConanRecipeManifest < Grape::Entity
        expose :recipe_urls, merge: true, documentation: { type: 'object', example: '{ "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz" }' }
      end
    end
  end
end
