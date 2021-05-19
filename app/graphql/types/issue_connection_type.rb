# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class IssueConnectionType < CountableConnectionType
  end
end

Types::IssueConnectionType.prepend_mod_with('Types::IssueConnectionType')
