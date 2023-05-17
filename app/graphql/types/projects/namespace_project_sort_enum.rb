# frozen_string_literal: true

module Types
  module Projects
    class NamespaceProjectSortEnum < BaseEnum
      graphql_name 'NamespaceProjectSort'
      description 'Values for sorting projects'

      value 'SIMILARITY', 'Most similar to the search query.', value: :similarity
      value 'ACTIVITY_DESC', 'Sort by latest activity, descending order.', value: :latest_activity_desc
    end
  end
end

Types::Projects::NamespaceProjectSortEnum.prepend_mod
