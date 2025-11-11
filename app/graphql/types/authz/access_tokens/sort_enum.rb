# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      class SortEnum < BaseEnum
        graphql_name 'AccessTokenSort'

        description 'Values for sorting access tokens.'

        value 'CREATED_DESC', value: 'created_desc', description: 'Sort by created_at in descending order.'
        value 'CREATED_ASC', value: 'created_asc', description: 'Sort by created_at in ascending order.'
        value 'UPDATED_DESC', value: 'updated_desc', description: 'Sort by updated_at in descending order.'
        value 'UPDATED_ASC', value: 'updated_asc', description: 'Sort by updated_at in ascending order.'
        value 'EXPIRES_DESC', value: 'expires_desc', description: 'Sort by expires_at in descending order.'
        value 'EXPIRES_ASC', value: 'expires_asc', description: 'Sort by expires_at in ascending order.'
        value 'LAST_USED_DESC', value: 'last_used_desc', description: 'Sort by last_used_at in descending order.'
        value 'LAST_USED_ASC', value: 'last_used_asc', description: 'Sort by last_used_at in ascending order.'
        value 'ID_DESC', value: 'id_desc', description: 'Sort by ID in descending order.'
        value 'ID_ASC', value: 'id_asc', description: 'Sort by ID in ascending order.'
        value 'NAME_DESC', value: 'name_desc', description: 'Sort by name in descending order.'
        value 'NAME_ASC', value: 'name_asc', description: 'Sort by name in ascending order.'
      end
    end
  end
end
