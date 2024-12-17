# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      # rubocop: disable Graphql/AuthorizeTypes -- this is static data
      class JobTokenPolicyCategoryType < BaseObject
        graphql_name 'JobTokenPolicyCategory'
        description 'Job token policy category type'

        field :description, GraphQL::Types::String, description: 'Description of the category.'
        field :policies, [Types::Ci::JobTokenScope::JobTokenPolicyType], description: 'Policies of the category.'
        field :text, GraphQL::Types::String, description: 'Display text of the category.'
        field :value, Types::Ci::JobTokenScope::PolicyCategoriesEnum, description: 'Value of the category.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
