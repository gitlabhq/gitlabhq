# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class BaseMergeRequestResolver < BaseCountResolver
        type Types::Analytics::CycleAnalytics::MetricType, null: true

        argument :assignee_usernames, [GraphQL::Types::String],
          required: false,
          description: 'Usernames of users assigned to the merge request.'

        argument :author_username, GraphQL::Types::String,
          required: false,
          description: 'Username of the author of the merge request.'

        argument :milestone_title, GraphQL::Types::String,
          required: false,
          description: 'Milestone applied to the merge request.'

        argument :label_names, [GraphQL::Types::String],
          required: false,
          description: 'Labels applied to the merge request.'
      end
    end
  end
end
