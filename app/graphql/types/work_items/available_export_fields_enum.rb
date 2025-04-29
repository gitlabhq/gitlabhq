# frozen_string_literal: true

module Types
  module WorkItems
    class AvailableExportFieldsEnum < BaseEnum
      graphql_name 'AvailableExportFields'
      description 'Available fields to be exported as CSV'

      value 'ASSIGNEE', value: 'assignee', description: 'Assignee(s) name of the work item.'
      value 'ASSIGNEE_USERNAME', value: 'assignee username', description: 'Assignee(s) username of the work item.'

      value 'AUTHOR', value: 'author', description: 'Author name of the work item.'
      value 'AUTHOR_USERNAME', value: 'author username', description: 'Author username of the work item.'

      value 'CONFIDENTIAL', value: 'confidential', description: 'Confidentiality flag of the work item.'
      value 'DESCRIPTION', value: 'description', description: 'Description of the work item.'

      value 'ID', value: 'id', description: 'Unique identifier of the work item.'
      value 'IID', value: 'iid', description: 'IID identifier of the work item.'

      value 'LOCKED', value: 'locked', description: 'Locked discussions flag of the work item.'

      value 'START_DATE', value: 'start date', description: 'Start date (UTC) of the work item.'
      value 'DUE_DATE', value: 'due date', description: 'Due date (UTC) of the work item.'

      value 'CLOSED_AT', value: 'closed at', description: 'Closed at (UTC) date of the work item.'
      value 'CREATED_AT', value: 'created at', description: 'Crated at (UTC) date of the work item.'
      value 'UPDATED_AT', value: 'updated at', description: 'Updated at (UTC) date of the work item.'

      value 'MILESTONE', value: 'milestone', description: 'Milestone of the work item.'

      value 'PARENT_ID', value: 'parent id', description: 'Parent ID of the work item.'
      value 'PARENT_IID', value: 'parent iid', description: 'Parent IID of the work item.'
      value 'PARENT_TITLE', value: 'parent title', description: 'Parent title of the work item.'

      value 'STATE', value: 'state', description: 'State of the work item.'

      value 'TITLE', value: 'title', description: 'Title of the work item.'
      value 'TIME_ESTIMATE', value: 'time estimate', description: 'Time estimate of the work item.'
      value 'TIME_SPENT', value: 'time spent', description: 'Time spent of the work item.'
      value 'TYPE', value: 'type', description: 'Type of the work item.'

      value 'URL', value: 'url', description: 'Web URL to the work item.'
    end
  end
end

Types::WorkItems::AvailableExportFieldsEnum.prepend_mod
