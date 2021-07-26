# frozen_string_literal: true

module Types
  module CiConfiguration
    module Sast
      class EntityInputType < BaseInputObject
        graphql_name 'SastCiConfigurationEntityInput'
        description 'Represents an entity in SAST CI configuration'

        argument :field, GraphQL::Types::String, required: true,
          description: 'CI keyword of entity.'

        argument :default_value, GraphQL::Types::String, required: true,
          description: 'Default value that is used if value is empty.'

        argument :value, GraphQL::Types::String, required: true,
          description: 'Current value of the entity.'
      end
    end
  end
end
