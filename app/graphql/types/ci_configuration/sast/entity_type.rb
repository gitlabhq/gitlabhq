# frozen_string_literal: true

module Types
  module CiConfiguration
    module Sast
      # rubocop: disable Graphql/AuthorizeTypes
      class EntityType < BaseObject
        graphql_name 'SastCiConfigurationEntity'
        description 'Represents an entity in SAST CI configuration'

        field :field, GraphQL::Types::String, null: true,
          description: 'CI keyword of entity.'

        field :label, GraphQL::Types::String, null: true,
          description: 'Label for entity used in the form.'

        field :type, GraphQL::Types::String, null: true,
          description: 'Type of the field value.'

        field :options, ::Types::CiConfiguration::Sast::OptionsEntityType.connection_type, null: true,
          description: 'Different possible values of the field.'

        field :default_value, GraphQL::Types::String, null: true,
          description: 'Default value that is used if value is empty.'

        field :description, GraphQL::Types::String, null: true,
          description: 'Entity description that is displayed on the form.'

        field :value, GraphQL::Types::String, null: true,
          description: 'Current value of the entity.'

        field :size, ::Types::CiConfiguration::Sast::UiComponentSizeEnum, null: true,
          description: 'Size of the UI component.'
      end
    end
  end
end
