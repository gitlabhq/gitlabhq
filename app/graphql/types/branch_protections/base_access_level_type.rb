# frozen_string_literal: true

module Types
  module BranchProtections
    class BaseAccessLevelType < Types::BaseObject
      authorize :read_protected_branch

      # rubocop:disable Graphql::AccessLevelEnum -- Introduced before the cop
      field :access_level,
        type: GraphQL::Types::Int,
        null: false,
        description: 'GitLab::Access level.'
      # rubocop:enable Graphql::AccessLevelEnum

      field :access_level_description,
        type: GraphQL::Types::String,
        null: false,
        description: 'Human readable representation for the access level.',
        method: 'humanize'
    end
  end
end

Types::BranchProtections::BaseAccessLevelType.prepend_mod
