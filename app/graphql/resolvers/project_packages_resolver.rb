# frozen_string_literal: true

module Resolvers
  class ProjectPackagesResolver < BaseResolver
    type Types::Packages::PackageType.connection_type, null: true

    def resolve(**args)
      return unless packages_available?

      ::Packages::PackagesFinder.new(object).execute
    end

    private

    def packages_available?
      ::Gitlab.config.packages.enabled
    end
  end
end
