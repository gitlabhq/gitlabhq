# frozen_string_literal: true

module Resolvers
  class PackagesResolver < BaseResolver
    type Types::PackageType, null: true

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
