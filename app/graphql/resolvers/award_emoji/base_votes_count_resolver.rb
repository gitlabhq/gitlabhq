# frozen_string_literal: true

module Resolvers
  module AwardEmoji
    class BaseVotesCountResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type GraphQL::Types::Int, null: true

      private

      def authorized_resource?(object)
        Ability.allowed?(current_user, "read_#{object.to_ability_name}".to_sym, object)
      end

      def votes_batch_loader
        BatchLoaders::AwardEmojiVotesBatchLoader
      end
    end
  end
end
