# frozen_string_literal: true

module Types
  module Projects
    class ArchivedEnum < BaseEnum
      graphql_name 'ProjectArchived'
      description 'Values for the archived argument'

      value 'ONLY', 'Only archived projects.', value: 'only'
      value 'INCLUDE', 'Include archvied projects.', value: true
      value 'EXCLUDE', 'Exclude archived projects.', value: false
    end
  end
end
