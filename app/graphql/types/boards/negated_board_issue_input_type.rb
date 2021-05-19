# frozen_string_literal: true

module Types
  module Boards
    class NegatedBoardIssueInputType < BoardIssueInputBaseType
    end
  end
end

Types::Boards::NegatedBoardIssueInputType.prepend_mod_with('Types::Boards::NegatedBoardIssueInputType')
