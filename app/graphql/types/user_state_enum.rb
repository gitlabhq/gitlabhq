# frozen_string_literal: true

module Types
  class UserStateEnum < BaseEnum
    graphql_name 'UserState'
    description 'Possible states of a user'

    value 'active', 'User is active and can use the system.', value: 'active'
    value 'blocked', 'User has been blocked by an administrator and cannot use the system.', value: 'blocked'
    value 'deactivated', 'User is no longer active and cannot use the system.', value: 'deactivated'
    value 'banned', 'User is blocked, and their contributions are hidden.', value: 'banned'
    value 'ldap_blocked', 'User has been blocked by the system.', value: 'ldap_blocked'
    value 'blocked_pending_approval', 'User is blocked and pending approval.', value: 'blocked_pending_approval'
  end
end
