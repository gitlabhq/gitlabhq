# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Conan
        class RecipeFilesList < Grape::Entity
          expose :files, documentation: {
            type: 'object',
            example: '{ "files" : { "conan_sources.tgz" : { }, "conanmanifest.txt" : { }, "conanfile.py" : { } } }'
          } do |obj|
            obj[:files].each_with_object({}) { |file, files| files[file.file_name] = {} }
          end
        end
      end
    end
  end
end
