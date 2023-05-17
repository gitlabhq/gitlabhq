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

        # :project level: no customization, returning the original resolver
        # :group level: add the project_ids argument
        def self.[](context = :project)
          case context
          when :project
            self
          when :group
            Class.new(self) do
              argument :project_ids, [GraphQL::Types::ID],
                required: false,
                description: 'Project IDs within the group hierarchy.'

              define_method :finder_params do
                { group_id: object.id, include_subgroups: true }
              end
            end
          end
        end
      end
    end
  end
end
