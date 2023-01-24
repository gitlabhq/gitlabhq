# frozen_string_literal: true

module Types
  module Projects
    class NamespaceProjectSortEnum < BaseEnum
      graphql_name 'NamespaceProjectSort'
      description 'Values for sorting projects'

      value 'SIMILARITY', 'Most similar to the search query.', value: :similarity
      value 'STORAGE', 'Sort by storage size.', value: :storage
      value 'ACTIVITY_DESC', 'Sort by latest activity, in descending order.', value: :latest_activity_desc
    end
  end
end
