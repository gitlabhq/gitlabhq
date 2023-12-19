# frozen_string_literal: true

module Types
  # rubocop:disable Graphql/AuthorizeTypes -- This is not necessary because the superclass declares the authorization
  class CurrentUserType < ::Types::UserType
    graphql_name 'CurrentUser'
    description 'The currently authenticated GitLab user.'
  end
  # rubocop:enable Graphql/AuthorizeTypes
end

::Types::CurrentUserType.prepend_mod
