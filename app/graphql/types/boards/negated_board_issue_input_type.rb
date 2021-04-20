# frozen_string_literal: true

module Types
  module Boards
    class NegatedBoardIssueInputType < BoardIssueInputBaseType
    end
  end
end

Types::Boards::NegatedBoardIssueInputType.prepend_if_ee('::EE::Types::Boards::NegatedBoardIssueInputType')
