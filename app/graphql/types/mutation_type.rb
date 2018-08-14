# frozen_string_literal: true

module Types
  class MutationType < BaseObject
    include Gitlab::Graphql::MountMutation

    graphql_name "Mutation"

    mount_mutation Mutations::MergeRequests::SetWip
  end
end
