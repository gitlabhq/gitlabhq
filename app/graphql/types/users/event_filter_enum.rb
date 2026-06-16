# frozen_string_literal: true

module Types
  module Users
    class EventFilterEnum < BaseEnum
      graphql_name 'UserEventFilter'
      description 'Filter for user activity events.'

      value 'ALL', value: ::EventFilter::ALL, description: 'All events.'
      value 'PUSH', value: ::EventFilter::PUSH, description: 'Push events.'
      value 'MERGED', value: ::EventFilter::MERGED, description: 'Merge events.'
      value 'ISSUE', value: ::EventFilter::ISSUE, description: 'Issue events.'
      value 'COMMENTS', value: ::EventFilter::COMMENTS, description: 'Comment events.'
      value 'TEAM', value: ::EventFilter::TEAM, description: 'Team events.'
      value 'WIKI', value: ::EventFilter::WIKI, description: 'Wiki page events.'
      value 'DESIGNS', value: ::EventFilter::DESIGNS, description: 'Design events.'
    end
  end
end

Types::Users::EventFilterEnum.prepend_mod
