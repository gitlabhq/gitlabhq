# frozen_string_literal: true

module Gitlab
  module Graphql
    module Errors
      BaseError = Class.new(GraphQL::ExecutionError)
      ArgumentError = Class.new(BaseError)

      # This error class is abstract: raise a subclass, not this class.
      # Only the subclasses are registered in GraphqlController::ERROR_STATUS_MAP,
      # which keys on the exact class, so raising this directly returns a 500.
      class OrganizationMaintenanceModeError < BaseError
        attr_reader :headers

        def initialize(message, headers: {})
          super(message)
          @headers = headers
        end
      end

      TimeBoundedOrganizationMaintenanceModeError = Class.new(OrganizationMaintenanceModeError)
      IndefiniteOrganizationMaintenanceModeError = Class.new(OrganizationMaintenanceModeError)

      ResourceNotAvailable = Class.new(BaseError)
      MutationError = Class.new(BaseError)
      LimitError = Class.new(BaseError)
      InvalidMembersError = Class.new(StandardError)
      InvalidMemberCountError = Class.new(StandardError)
    end
  end
end
