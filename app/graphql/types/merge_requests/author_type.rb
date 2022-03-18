# frozen_string_literal: true

module Types
  module MergeRequests
    class AuthorType < ::Types::UserType
      graphql_name 'MergeRequestAuthor'
      description 'The author of the merge request.'

      include ::Types::MergeRequests::InteractsWithMergeRequest

      authorize :read_user
    end
  end
end
