# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class IssueCountResolver < BaseResolver
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

        argument :from, Types::TimeType,
          required: true,
          description: 'Issues created after the date.'

        argument :to, Types::TimeType,
          required: true,
          description: 'Issues created before the date.'

        def resolve(**args)
          value = IssuesFinder
            .new(current_user, process_params(args))
            .execute
            .count

          {
            value: value,
            title: n_('New Issue', 'New Issues', value),
            identifier: 'issues',
            links: []
          }
        end

        private

        def process_params(params)
          params[:assignee_username] = params.delete(:assignee_usernames) if params[:assignee_usernames]
          params[:label_name] = params.delete(:label_names) if params[:label_names]
          params[:created_after] = params.delete(:from)
          params[:created_before] = params.delete(:to)
          params[:projects] = params[:project_ids] if params[:project_ids]

          params.merge(finder_params)
        end

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
