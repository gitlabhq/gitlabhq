# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryTagsSortEnum < BaseEnum
      graphql_name 'ContainerRepositoryTagSort'
      description 'Values for sorting tags'

      value 'NAME_ASC', 'Ordered by name in ascending order.', value: :name_asc
      value 'NAME_DESC', 'Ordered by name in descending order.', value: :name_desc
      value 'PUBLISHED_AT_ASC',
        'Ordered by published_at in ascending order. Only available for GitLab.com.', value: :published_at_asc
      value 'PUBLISHED_AT_DESC',
        'Ordered by published_at in descending order. Only available for GitLab.com.', value: :published_at_desc
    end
  end
end
