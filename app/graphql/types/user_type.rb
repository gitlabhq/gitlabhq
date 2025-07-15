# frozen_string_literal: true

module Types
  class UserType < ::Types::BaseObject
    graphql_name 'UserCore'
    description 'Core representation of a GitLab user.'

    connection_type_class Types::CountableConnectionType

    implements ::Types::UserInterface

    authorize :read_user

    def self.authorization_scopes
      super + [:ai_workflows]
    end

    present_using UserPresenter
  end
end

Types::UserType.prepend_mod
