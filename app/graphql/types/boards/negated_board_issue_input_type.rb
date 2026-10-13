# frozen_string_literal: true

module Types
  module Boards
    class NegatedBoardIssueInputType < BoardIssueInputBaseType
      # `authorUsername` (single) is inherited from the base type. `authorUsernames`
      # is additive so multi-author negation is supported without changing the
      # existing scalar argument's type (which would break API consumers passing
      # it as a variable). Both map to the finder's `author_username`.
      argument :author_usernames, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
        description: 'Filter by author usernames ' \
          "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."

      validates mutually_exclusive: [:author_username, :author_usernames]
    end
  end
end

Types::Boards::NegatedBoardIssueInputType.prepend_mod_with('Types::Boards::NegatedBoardIssueInputType')
