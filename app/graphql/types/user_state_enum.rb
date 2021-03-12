# frozen_string_literal: true

module Types
  class UserStateEnum < BaseEnum
    graphql_name 'UserState'
    description 'Possible states of a user'

    value 'active', 'The user is active and is able to use the system.', value: 'active'
    value 'blocked', 'The user has been blocked and is prevented from using the system.', value: 'blocked'
    value 'deactivated', 'The user is no longer active and is unable to use the system.', value: 'deactivated'
  end
end
