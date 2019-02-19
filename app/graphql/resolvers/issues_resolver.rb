# frozen_string_literal: true

module Resolvers
  class IssuesResolver < BaseResolver
    argument :iid, GraphQL::ID_TYPE,
              required: false,
              description: 'The IID of the issue, e.g., "1"'

    argument :iids, [GraphQL::ID_TYPE],
              required: false,
              description: 'The list of IIDs of issues, e.g., [1, 2]'

    argument :search, GraphQL::STRING_TYPE,
              required: false
    argument :sort, Types::Sort,
              required: false,
              default_value: 'created_desc'

    type Types::IssueType, null: true

    alias_method :project, :object

    def resolve(**args)
      # Will need to be be made group & namespace aware with
      # https://gitlab.com/gitlab-org/gitlab-ce/issues/54520
      args[:project_id] = project.id
      args[:iids] ||= [args[:iid]].compact

      IssuesFinder.new(context[:current_user], args).execute
    end
  end
end
