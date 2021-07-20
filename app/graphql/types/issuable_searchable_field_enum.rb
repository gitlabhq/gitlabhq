# frozen_string_literal: true

module Types
  class IssuableSearchableFieldEnum < BaseEnum
    graphql_name 'IssuableSearchableField'
    description 'Fields to perform the search in'

    Issuable::SEARCHABLE_FIELDS.each do |field|
      value field.upcase, value: field, description: "Search in #{field} field."
    end
  end
end
