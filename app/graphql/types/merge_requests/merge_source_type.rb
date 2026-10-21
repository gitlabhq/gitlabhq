# frozen_string_literal: true

module Types
  module MergeRequests
    # rubocop: disable Graphql/AuthorizeTypes -- reached only through MergeRequestType.mergeSource, which authorizes read_merge_request
    class MergeSourceType < BaseObject
      graphql_name 'MergeRequestMergeSource'
      description 'Merge request or pushed commit that caused a merge request to be marked as merged.'

      authorize_granular_token skip_reason: :parent_authorizes

      field :merge_request,
        ::Types::MergeRequestType,
        null: true,
        method: :source_merge_request,
        description: 'Merge request whose merge included the changes. ' \
          'Null when merged by a pushed commit, or when the current user cannot read the merge request.'

      field :commit_sha,
        GraphQL::Types::String,
        null: true,
        method: :source_commit,
        description: 'SHA of the pushed commit that included the changes. Null when merged through a merge request.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
