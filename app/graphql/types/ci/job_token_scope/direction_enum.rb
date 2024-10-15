# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      class DirectionEnum < BaseEnum
        graphql_name 'CiJobTokenScopeDirection'
        description 'Direction of access.'

        value 'OUTBOUND',
          value: :outbound,
          description: 'Job token scope project can access target project in the outbound allowlist.'

        value 'INBOUND',
          value: :inbound,
          description: 'Target projects in the inbound allowlist can access the scope project ' \
            'through their job tokens.'
      end
    end
  end
end
