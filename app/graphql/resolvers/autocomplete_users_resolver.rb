# frozen_string_literal: true

module Resolvers
  class AutocompleteUsersResolver < BaseResolver
    type [::Types::Users::AutocompletedUserType], null: true

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Query to search users by name, username, or public email.'

    def resolve(search: nil)
      ::Autocomplete::UsersFinder.new(
        current_user: context[:current_user],
        project: project,
        group: group,
        params: {
          search: search
        }
      ).execute
    end

    private

    def project
      object if object.is_a?(Project)
    end

    def group
      object if object.is_a?(Group)
    end
  end
end
