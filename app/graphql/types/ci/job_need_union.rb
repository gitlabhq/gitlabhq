# frozen_string_literal: true

module Types
  module Ci
    class JobNeedUnion < GraphQL::Schema::Union
      TypeNotSupportedError = Class.new(StandardError)

      possible_types Types::Ci::JobType, Types::Ci::BuildNeedType

      def self.resolve_type(object, context)
        case object
        when ::Ci::BuildNeed
          Types::Ci::BuildNeedType
        when CommitStatus
          Types::Ci::JobType
        else
          raise TypeNotSupportedError
        end
      end
    end
  end
end
