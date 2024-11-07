# frozen_string_literal: true

module Types
  module Organizations
    class GroupsProjectsSortEnum < SortEnum
      graphql_name 'OrganizationGroupProjectSort'
      description 'Values for sorting organization groups and projects.'

      value 'NAME_DESC', 'Name descending order.', value: :name_desc, experiment: { milestone: '17.2' }
      value 'NAME_ASC', 'Name ascending order.', value: :name_asc, experiment: { milestone: '17.2' }
    end
  end
end
