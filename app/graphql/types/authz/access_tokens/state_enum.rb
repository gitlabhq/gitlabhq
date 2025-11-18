# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      class StateEnum < BaseEnum
        graphql_name 'AccessTokenState'

        description 'State of an access token.'

        value 'ACTIVE', value: 'active', description: 'Token is active.'
        value 'INACTIVE', value: 'inactive', description: 'Token is inactive.'
      end
    end
  end
end
