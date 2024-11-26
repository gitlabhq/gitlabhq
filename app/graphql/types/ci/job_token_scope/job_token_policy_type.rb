# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      # rubocop: disable Graphql/AuthorizeTypes -- this is static data
      class JobTokenPolicyType < BaseObject
        graphql_name 'JobTokenPolicy'
        description 'Job token policy'

        field :description, GraphQL::Types::String, description: 'Description of the job token policy.'
        field :text, GraphQL::Types::String, description: 'Display text of the job token policy.'
        field :type, Types::Ci::JobTokenScope::PolicyTypesEnum, description: 'Job token policy type.'
        field :value, Types::Ci::JobTokenScope::PoliciesEnum, description: 'Value of the job token policy.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
