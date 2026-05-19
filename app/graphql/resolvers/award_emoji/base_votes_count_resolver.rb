# frozen_string_literal: true

module Resolvers
  module AwardEmoji
    class BaseVotesCountResolver < BaseResolver
      type GraphQL::Types::Int, null: true

      private

      def votes_batch_loader
        BatchLoaders::AwardEmojiVotesBatchLoader
      end
    end
  end
end
