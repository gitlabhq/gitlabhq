# frozen_string_literal: true

module Resolvers
  module Projects
    class DeployKeyResolver < BaseResolver
      include LooksAhead
      type Types::AccessLevels::DeployKeyType, null: true

      def resolve_with_lookahead(**args)
        apply_lookahead(Autocomplete::DeployKeysWithWriteAccessFinder.new(current_user,
          object).execute(title_search_term: args[:title_query]))
      end

      def preloads
        {
          user: [:user]
        }
      end
    end
  end
end
