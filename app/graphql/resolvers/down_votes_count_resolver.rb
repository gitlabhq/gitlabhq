# frozen_string_literal: true

module Resolvers
  class DownVotesCountResolver < Resolvers::AwardEmoji::BaseVotesCountResolver
    type GraphQL::Types::Int, null: true

    def resolve
      authorize!(object)
      votes_batch_loader.load_downvotes(object)
    end
  end
end
