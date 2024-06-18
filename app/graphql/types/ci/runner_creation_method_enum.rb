# frozen_string_literal: true

module Types
  module Ci
    class RunnerCreationMethodEnum < BaseEnum
      graphql_name 'CiRunnerCreationMethod'

      value 'REGISTRATION_TOKEN',
        description: 'Applies to a runner that was created by a runner registration token.',
        value: 'registration_token'
      value 'AUTHENTICATED_USER',
        description: 'Applies to a runner that was created by an authenticated user.',
        value: 'authenticated_user'
    end
  end
end
