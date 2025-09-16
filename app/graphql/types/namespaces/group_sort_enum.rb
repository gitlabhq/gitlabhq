# frozen_string_literal: true

module Types
  module Namespaces
    class GroupSortEnum < BaseEnum
      graphql_name 'GroupSort'
      description 'Values for sorting groups'

      value 'SIMILARITY',
        'Most similar to the search query.',
        value: :similarity

      value 'CREATED_AT_ASC',
        'Sort by created at, ascending order.',
        value: :created_at_asc
      value 'CREATED_AT_DESC',
        'Sort by created at, descending order.',
        value: :created_at_desc

      value 'UPDATED_AT_ASC',
        'Sort by updated at, ascending order.',
        value: :updated_at_asc
      value 'UPDATED_AT_DESC',
        'Sort by updated at, descending order.',
        value: :updated_at_desc

      value 'NAME_ASC',
        'Sort by name, ascending order.',
        value: :name_asc
      value 'NAME_DESC',
        'Sort by name, descending order.',
        value: :name_desc

      value 'PATH_ASC',
        'Sort by path, ascending order.',
        value: :path_asc
      value 'PATH_DESC',
        'Sort by path, descending order.',
        value: :path_desc

      value 'ID_ASC',
        'Sort by ID, ascending order.',
        value: :id_asc
      value 'ID_DESC',
        'Sort by ID, descending order.',
        value: :id_desc
    end
  end
end
