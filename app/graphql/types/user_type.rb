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

    field :custom_attributes, [Types::CustomAttributeType],
      null: true,
      description: 'Custom attributes of the user. Only available to admins.',
      authorize: :read_custom_attribute
  end
end

Types::UserType.prepend_mod
