# frozen_string_literal: true

module Types
  module Namespaces
    class SidebarType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
      graphql_name 'NamespaceSidebar'

      alias_method :namespace, :object

      field :open_issues_count,
        GraphQL::Types::Int,
        null: true,
        description: 'Number of open issues of the namespace.'

      field :open_merge_requests_count, # rubocop:disable GraphQL/ExtractType -- no need to extract these into a field named "open"
        GraphQL::Types::Int,
        null: true,
        description: 'Number of open merge requests of the namespace.'

      def open_issues_count
        case namespace
        when ::Group
          group_open_issues_count
        when ::Namespaces::ProjectNamespace
          namespace.project.open_issues_count(context[:current_user])
        end
      end

      def open_merge_requests_count
        case namespace
        when Group
          ::Groups::MergeRequestsCountService.new(namespace, context[:current_user]).count
        when ::Namespaces::ProjectNamespace
          namespace.project.open_merge_requests_count
        end
      end

      def group_open_issues_count
        ::Groups::OpenIssuesCountService.new(namespace, context[:current_user], fast_timeout: true).count
      rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- used with fast_read_statement_timeout to prevent this count from slowing down the rest of the request
        Gitlab::ErrorTracking.log_exception(e, group_id: namespace.id, query: 'group_sidebar_issues_count')

        nil
      end
    end
  end
end

Types::Namespaces::SidebarType.prepend_mod
