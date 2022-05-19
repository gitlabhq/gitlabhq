# frozen_string_literal: true

module Resolvers
  class PackageDetailsResolver < BaseResolver
    type ::Types::Packages::PackageDetailsType, null: true

    argument :id, ::Types::GlobalIDType[::Packages::Package],
      required: true,
      description: 'Global ID of the package.'

    def ready?(**args)
      context[self.class] ||= { executions: 0 }
      context[self.class][:executions] += 1
      raise GraphQL::ExecutionError, "Package details can be requested only for one package at a time" if context[self.class][:executions] > 1

      super
    end

    def resolve(id:)
      GitlabSchema.find_by_gid(id)
    end
  end
end
