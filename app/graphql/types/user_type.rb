# frozen_string_literal: true

module Types
  class UserType < ::Types::BaseObject
    graphql_name 'UserCore'
    description 'Core represention of a GitLab user.'
    implements ::Types::UserInterface

    authorize :read_user

    present_using UserPresenter
  end
end
