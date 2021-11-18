# frozen_string_literal: true

module Types
  class ReleaseTagWildcardIdEnum < BaseEnum
    graphql_name 'ReleaseTagWildcardId'
    description 'Release tag ID wildcard values'

    value 'NONE', 'No release tag is assigned.'
    value 'ANY', 'Release tag is assigned.'
  end
end
