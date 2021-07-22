# frozen_string_literal: true

module Types
  module Packages
    module Composer
      class MetadatumType < BaseObject
        graphql_name 'ComposerMetadata'
        description 'Composer metadata'

        authorize :read_package

        field :target_sha, GraphQL::Types::String, null: false, description: 'Target SHA of the package.'
        field :composer_json, Types::Packages::Composer::JsonType, null: false, description: 'Data of the Composer JSON file.'
      end
    end
  end
end
