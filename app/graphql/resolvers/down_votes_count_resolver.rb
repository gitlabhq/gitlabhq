# frozen_string_literal: true

module Resolvers
  class DownVotesCountResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include BatchLoaders::AwardEmojiVotesBatchLoader

    type GraphQL::Types::Int, null: true

    def resolve
      authorize!(object)
      load_votes(object, AwardEmoji::DOWNVOTE_NAME)
    end
  end
end
