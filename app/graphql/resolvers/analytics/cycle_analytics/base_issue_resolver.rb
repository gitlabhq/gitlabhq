# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class BaseIssueResolver < BaseCountResolver
        type Types::Analytics::CycleAnalytics::MetricType, null: true

        argument :assignee_usernames, [GraphQL::Types::String],
          required: false,
          description: 'Usernames of users assigned to the issue.'

        argument :author_username, GraphQL::Types::String,
          required: false,
          description: 'Username of the author of the issue.'

        argument :milestone_title, GraphQL::Types::String,
          required: false,
          description: 'Milestone applied to the issue.'

        argument :label_names, [GraphQL::Types::String],
          required: false,
          description: 'Labels applied to the issue.'

        def finder_params
          { project_id: object.project.id }
        end
      end
    end
  end
end

Resolvers::Analytics::CycleAnalytics::BaseIssueResolver.prepend_mod
