# frozen_string_literal: true

module Types
  class SortEnum < BaseEnum
    graphql_name 'Sort'
    description 'Common sort values'

    value 'updated_desc', 'Updated at descending order'
    value 'updated_asc', 'Updated at ascending order'
    value 'created_desc', 'Created at descending order'
    value 'created_asc', 'Created at ascending order'
  end
end
