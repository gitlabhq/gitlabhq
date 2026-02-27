# frozen_string_literal: true

module Types
  module Packages
    module Conan
      class MetadatumFileTypeEnum < BaseEnum
        graphql_name 'ConanMetadatumFileTypeEnum'
        description 'Conan file types'

        ::Packages::Conan::FileMetadatum.conan_file_types.each_key do |file|
          value file.upcase, value: file, description: "A #{file.humanize(capitalize: false)} type."
        end
      end
    end
  end
end
