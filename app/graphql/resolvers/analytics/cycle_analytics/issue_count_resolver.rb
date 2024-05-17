# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType -- inherited from Resolvers::Analytics::CycleAnalytics::BaseIssueResolver
module Resolvers
  module Analytics
    module CycleAnalytics
      class IssueCountResolver < BaseIssueResolver
        def resolve(**args)
          value = IssuesFinder
            .new(current_user, process_params(args))
            .execute
            .count

          {
            value: value,
            title: n_('New issue', 'New issues', value),
            identifier: 'issues',
            links: []
          }
        end

        private

        def process_params(params)
          assignees_value = params.delete(:assignee_usernames)
          params[:assignee_username] = assignees_value if assignees_value.present?
          params[:label_name] = params.delete(:label_names) if params[:label_names]
          params[:created_after] = params.delete(:from)
          params[:created_before] = params.delete(:to)
          params[:projects] = params[:project_ids] if params[:project_ids]

          params.merge(finder_params)
        end
      end
    end
  end
end
# rubocop:enable Graphql/ResolverType
