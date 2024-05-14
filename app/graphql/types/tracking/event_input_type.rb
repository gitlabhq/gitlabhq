# frozen_string_literal: true

module Types
  module Tracking
    class EventInputType < BaseInputObject
      graphql_name 'TrackingEventInput'
      description 'Attributes for defining a tracking event.'

      argument :action, GraphQL::Types::String, required: true, description: 'Event action.'
      argument :category, GraphQL::Types::String, required: true, description: 'Event category.'
      argument :extra, GraphQL::Types::JSON, required: false, description: 'Extra metadata for the event.' # rubocop:disable Graphql/JSONType -- extra can have an arbitrary structure
      argument :label, GraphQL::Types::String, required: false, description: 'Event label.'
      argument :property, GraphQL::Types::String, required: false, description: 'Event property.'
      argument :value, GraphQL::Types::String, required: false, description: 'Event value.'
    end
  end
end
