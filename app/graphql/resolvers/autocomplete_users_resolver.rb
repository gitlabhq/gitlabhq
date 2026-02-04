# frozen_string_literal: true

module Resolvers
  class AutocompleteUsersResolver < BaseResolver
    type [::Types::Users::AutocompletedUserType], null: true

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Query to search users by name, username, or public email.'

    def resolve(**args)
      ::Autocomplete::UsersFinder.new(
        current_user: context[:current_user],
        project: project,
        group: group,
        params: finder_params(args)
      ).execute
    end

    private

    def project
      object if object.is_a?(Project)
    end

    def group
      object if object.is_a?(Group)
    end

    def finder_params(args)
      {
        search: args[:search]
      }
    end
  end
end

Resolvers::AutocompleteUsersResolver.prepend_mod_with('Resolvers::AutocompleteUsersResolver')
