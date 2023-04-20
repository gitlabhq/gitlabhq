# frozen_string_literal: true

module Types
  module WorkItems
    class AvailableExportFieldsEnum < BaseEnum
      graphql_name 'AvailableExportFields'
      description 'Available fields to be exported as CSV'

      value 'ID', value: 'id', description: 'Unique identifier.'
      value 'TITLE', value: 'title', description: 'Title.'
      value 'DESCRIPTION', value: 'description', description: 'Description.'
      value 'TYPE', value: 'type', description: 'Type of the work item.'
      value 'AUTHOR', value: 'author', description: 'Author name.'
      value 'AUTHOR_USERNAME', value: 'author username', description: 'Author username.'
      value 'CREATED_AT', value: 'created_at', description: 'Date of creation.'
    end
  end
end
