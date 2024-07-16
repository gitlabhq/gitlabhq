# frozen_string_literal: true

module Types
  module Import
    class SourceUserSortEnum < BaseEnum
      graphql_name 'SourceUserSort'
      description 'Values for sorting the mapping of users on source instance to users on destination instance.'

      value 'STATUS_ASC', 'Status of the mapping by ascending order.', value: :status_asc
      value 'STATUS_DESC', 'Status of the mapping by descending order.', value: :status_desc
      value 'SOURCE_NAME_ASC', 'Instance source name by ascending order.', value: :source_name_asc
      value 'SOURCE_NAME_DESC', 'Instance source name by descending order.', value: :source_name_desc
    end
  end
end
