# frozen_string_literal: true

module Types
  class ReviewerWildcardIdEnum < BaseEnum
    graphql_name 'ReviewerWildcardId'
    description 'Reviewer ID wildcard values'

    value 'NONE', 'No reviewer is assigned.'
    value 'ANY', 'Any reviewer is assigned.'
  end
end
