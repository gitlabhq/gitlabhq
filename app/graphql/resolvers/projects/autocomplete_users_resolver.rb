# frozen_string_literal: true

module Resolvers
  module Projects
    class AutocompleteUsersResolver < BaseResolver
      type [::Types::Users::AutocompletedUserType], null: true

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Query to search users by name, username, or public email.'

      alias_method :project, :object

      def resolve(search: nil)
        ::Autocomplete::UsersFinder.new(
          current_user: context[:current_user],
          project: project,
          group: nil,
          params: {
            search: search
          }
        ).execute
      end
    end
  end
end
