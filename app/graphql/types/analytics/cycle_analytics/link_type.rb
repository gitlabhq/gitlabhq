# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      # rubocop: disable Graphql/AuthorizeTypes
      class LinkType < BaseObject
        graphql_name 'ValueStreamMetricLinkType'

        field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Name of the link group.'

        field :label,
          GraphQL::Types::String,
          null: false,
          description: 'Label for the link.'

        field :url,
          GraphQL::Types::String,
          null: false,
          description: 'Drill-down URL.'

        field :docs_link,
          GraphQL::Types::Boolean,
          null: true,
          description: 'Link to the metric documentation.'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
