# frozen_string_literal: true

module Resolvers
  class GroupPackagesResolver < BaseResolver
    type Types::Packages::PackageType.connection_type, null: true

    def ready?(**args)
      context[self.class] ||= { executions: 0 }
      context[self.class][:executions] += 1
      raise GraphQL::ExecutionError, "Packages can be requested only for one group at a time" if context[self.class][:executions] > 1

      super
    end

    def resolve(**args)
      return unless packages_available?

      ::Packages::GroupPackagesFinder.new(current_user, object).execute
    end

    private

    def packages_available?
      ::Gitlab.config.packages.enabled
    end
  end
end
