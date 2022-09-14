# frozen_string_literal: true

module Resolvers
  class PackageDetailsResolver < BaseResolver
    extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

    type ::Types::Packages::PackageDetailsType, null: true

    argument :id, ::Types::GlobalIDType[::Packages::Package],
      required: true,
      description: 'Global ID of the package.'

    def resolve(id:)
      GitlabSchema.find_by_gid(id)
    end
  end
end
