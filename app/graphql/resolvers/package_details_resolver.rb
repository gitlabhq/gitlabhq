# frozen_string_literal: true

module Resolvers
  # No return types defined because they can be different.
  # rubocop: disable Graphql/ResolverType
  class PackageDetailsResolver < BaseResolver
    argument :id, ::Types::GlobalIDType[::Packages::Package],
      required: true,
      description: 'The global ID of the package.'

    def resolve(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[::Packages::Package].coerce_isolated_input(id)
      GitlabSchema.find_by_gid(id)
    end
  end
end
