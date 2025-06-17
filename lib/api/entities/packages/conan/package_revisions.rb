# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Conan
        class PackageRevisions < Grape::Entity
          expose :package_reference, as: :packageReference, documentation: {
            type: String,
            desc: 'The Conan package reference',
            example: 'packageTest/1.2.3@gitlab-org+conan/stable#1883c9f810f2d6e5b59d5285c7141970:' \
              '133a1f2158ff2cf69739f316ec21143785be54c7'
          }

          expose :package_revisions, as: :revisions, using:
          ::API::Entities::Packages::Conan::Revision, documentation: {
            type: Array,
            desc: 'List of package revisions',
            is_array: true
          }
        end
      end
    end
  end
end
