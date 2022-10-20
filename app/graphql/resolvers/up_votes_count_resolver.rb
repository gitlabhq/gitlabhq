# frozen_string_literal: true

module Resolvers
  class UpVotesCountResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include BatchLoaders::AwardEmojiVotesBatchLoader

    type GraphQL::Types::Int, null: true

    def resolve
      authorize!(object)
      load_votes(object, AwardEmoji::UPVOTE_NAME)
    end
  end
end
