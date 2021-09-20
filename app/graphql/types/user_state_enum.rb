# frozen_string_literal: true

module Types
  class UserStateEnum < BaseEnum
    graphql_name 'UserState'
    description 'Possible states of a user'

    value 'active', 'User is active and is able to use the system.', value: 'active'
    value 'blocked', 'User has been blocked and is prevented from using the system.', value: 'blocked'
    value 'deactivated', 'User is no longer active and is unable to use the system.', value: 'deactivated'
  end
end
