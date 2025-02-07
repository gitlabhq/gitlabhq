# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      class TargetType < BaseUnion
        graphql_name 'CiJobTokenScopeTarget'
        description 'Represents an object that is the target of a CI_JOB_TOKEN allowlist entry'

        possible_types Types::Ci::JobTokenAccessibleProjectType, Types::Ci::JobTokenAccessibleGroupType

        def self.resolve_type(object, _context)
          case object
          when Project
            Types::Ci::JobTokenAccessibleProjectType
          when Group
            Types::Ci::JobTokenAccessibleGroupType
          else
            raise 'Unsupported CI job token scope target type'
          end
        end
      end
    end
  end
end
