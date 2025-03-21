# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Conan
        class PackageSnapshot < Grape::Entity
          expose :package_snapshot, merge: true,
            documentation: {
              type: 'object',
              example: '{ "conan_package.tgz": "749b29bdf72587081ca03ec033ee59dc" }'
            }
        end
      end
    end
  end
end
