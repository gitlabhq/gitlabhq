# frozen_string_literal: true

module Resolvers
  class UpVotesCountResolver < Resolvers::AwardEmoji::BaseVotesCountResolver
    type GraphQL::Types::Int, null: true

    def resolve
      authorize!(object)
      votes_batch_loader.load_upvotes(object)
    end
  end
end
