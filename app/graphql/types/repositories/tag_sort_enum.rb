# frozen_string_literal: true

module Types
  module Repositories
    class TagSortEnum < BaseEnum
      graphql_name 'TagSort'
      description 'Values for sorting repository tags.'

      value 'NAME_ASC', value: 'name_asc', description: 'Name by ascending order.'
      value 'NAME_DESC', value: 'name_desc', description: 'Name by descending order.'
      value 'UPDATED_ASC', value: 'updated_asc', description: 'Tag creation date by ascending order.'
      value 'UPDATED_DESC', value: 'updated_desc', description: 'Tag creation date by descending order.'
      value 'VERSION_ASC', value: 'version_asc', description: 'Semantic version by ascending order.'
      value 'VERSION_DESC', value: 'version_desc', description: 'Semantic version by descending order.'
    end
  end
end
