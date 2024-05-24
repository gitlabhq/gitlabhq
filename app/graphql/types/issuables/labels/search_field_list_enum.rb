# frozen_string_literal: true

module Types
  module Issuables
    module Labels
      # rubocop: disable Search/NamespacedClass -- not search related
      class SearchFieldListEnum < BaseEnum
        graphql_name 'LabelSearchFieldList'
        description 'List of fields where the provided searchTerm should be looked up'

        value 'TITLE', 'Search in the label title.', value: :title
        value 'DESCRIPTION', 'Search in the label description.', value: :description
      end
      # rubocop: enable Search/NamespacedClass
    end
  end
end
