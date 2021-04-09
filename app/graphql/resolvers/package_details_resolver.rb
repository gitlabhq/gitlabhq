# frozen_string_literal: true

module Resolvers
  class PackageDetailsResolver < BaseResolver
    type ::Types::Packages::PackageDetailsType, null: true

    argument :id, ::Types::GlobalIDType[::Packages::Package],
      required: true,
      description: 'The global ID of the package.'

    def ready?(**args)
      context[self.class] ||= { executions: 0 }
      context[self.class][:executions] += 1
      raise GraphQL::ExecutionError, "Package details can be requested only for one package at a time" if context[self.class][:executions] > 1

      super
    end

    def resolve(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[::Packages::Package].coerce_isolated_input(id)
      GitlabSchema.find_by_gid(id)
    end
  end
end
