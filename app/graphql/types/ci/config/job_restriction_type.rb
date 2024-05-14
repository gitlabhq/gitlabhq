# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class JobRestrictionType < BaseObject
        graphql_name 'CiConfigJobRestriction'

        field :refs, [GraphQL::Types::String], null: true,
          description: 'Git refs the job restriction applies to.'
      end
    end
  end
end
