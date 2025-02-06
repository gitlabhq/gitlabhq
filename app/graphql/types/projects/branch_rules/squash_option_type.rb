# frozen_string_literal: true

module Types
  module Projects
    module BranchRules
      class SquashOptionType < Types::BaseObject
        graphql_name 'SquashOption'
        description 'Squash option overrides for a protected branch'
        accepts ::Projects::SquashOption
        authorize :read_squash_option
        present_using ::Projects::BranchRules::SquashOptionPresenter

        field :option,
          GraphQL::Types::String,
          null: false,
          description: 'Human-readable description of the squash option.',
          method: :human_squash_option

        field :help_text,
          GraphQL::Types::String,
          null: false,
          description: 'Help text for the squash option.'
      end
    end
  end
end
