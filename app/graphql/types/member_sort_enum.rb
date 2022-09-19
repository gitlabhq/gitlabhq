# frozen_string_literal: true

module Types
  class MemberSortEnum < SortEnum
    graphql_name 'MemberSort'
    description 'Values for sorting members'

    value 'ACCESS_LEVEL_ASC', 'Access level ascending order.', value: :access_level_asc
    value 'ACCESS_LEVEL_DESC', 'Access level descending order.', value: :access_level_desc
    value 'USER_FULL_NAME_ASC', "User's full name ascending order.", value: :name_asc
    value 'USER_FULL_NAME_DESC', "User's full name descending order.", value: :name_desc
  end
end
