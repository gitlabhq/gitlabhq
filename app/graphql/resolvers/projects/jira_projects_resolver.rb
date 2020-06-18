# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraProjectsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      argument :name,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'Project name or key'

      def resolve(name: nil, **args)
        authorize!(project)

        response, start_cursor, end_cursor = jira_projects(name: name, **compute_pagination_params(args))
        end_cursor = nil if !!response.payload[:is_last]

        if response.success?
          Gitlab::Graphql::ExternallyPaginatedArray.new(start_cursor, end_cursor, *response.payload[:projects])
        else
          raise Gitlab::Graphql::Errors::BaseError, response.message
        end
      end

      def authorized_resource?(project)
        Ability.allowed?(context[:current_user], :admin_project, project)
      end

      private

      alias_method :jira_service, :object

      def project
        jira_service&.project
      end

      def compute_pagination_params(params)
        after_cursor = Base64.decode64(params[:after].to_s)
        before_cursor = Base64.decode64(params[:before].to_s)

        # differentiate between 0 cursor and nil or invalid cursor that decodes into zero.
        after_index = after_cursor.to_i == 0 && after_cursor != "0" ? nil : after_cursor.to_i
        before_index = before_cursor.to_i == 0 && before_cursor != "0" ? nil : before_cursor.to_i

        if after_index.present? && before_index.present?
          if after_index >= before_index
            { start_at: 0, limit: 0 }
          else
            { start_at: after_index + 1, limit: before_index - after_index - 1 }
          end
        elsif after_index.present?
          { start_at: after_index + 1, limit: nil }
        elsif before_index.present?
          { start_at: 0, limit: before_index - 1 }
        else
          { start_at: 0, limit: nil }
        end
      end

      def jira_projects(name:, start_at:, limit:)
        args = { query: name, start_at: start_at, limit: limit }.compact

        response = Jira::Requests::Projects.new(project.jira_service, args).execute

        return [response, nil, nil] if response.error?

        projects = response.payload[:projects]
        start_cursor = start_at == 0 ? nil : Base64.encode64((start_at - 1).to_s)
        end_cursor = Base64.encode64((start_at + projects.size - 1).to_s)

        [response, start_cursor, end_cursor]
      end
    end
  end
end
