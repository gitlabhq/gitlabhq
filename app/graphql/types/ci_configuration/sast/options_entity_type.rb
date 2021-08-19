# frozen_string_literal: true

module Types
  module CiConfiguration
    module Sast
      # rubocop: disable Graphql/AuthorizeTypes
      class OptionsEntityType < BaseObject
        graphql_name 'SastCiConfigurationOptionsEntity'
        description 'Represents an entity for options in SAST CI configuration'

        field :label, GraphQL::Types::String, null: true,
          description: 'Label of option entity.'

        field :value, GraphQL::Types::String, null: true,
          description: 'Value of option entity.'
      end
    end
  end
end
