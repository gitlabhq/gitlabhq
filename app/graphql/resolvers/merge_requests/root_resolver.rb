# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class RootResolver < MergeRequestsResolver
      include ::Issuables::RootArguments

      UNSUPPORTED_ARGUMENTS = %w[search in].freeze

      type ::Types::MergeRequestType.connection_type, null: true

      accept_assignee
      accept_author
      accept_reviewer

      argument :include_archived, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Whether to include merge requests from archived projects. Defaults to `false`.'

      before_connection_authorization do |merge_requests, current_user|
        ::Preloaders::IssuablesPreloader.new(merge_requests, current_user, project_associations).preload_all
      end

      def self.project_associations
        [:namespace, :organization, :project_feature, :project_namespace]
      end

      def self.arguments(context = GraphQL::Query::NullContext.instance, require_defined_arguments = true)
        super.except(*UNSUPPORTED_ARGUMENTS)
      end

      def self.all_argument_definitions
        super.reject { |argument| argument.graphql_name.in?(UNSUPPORTED_ARGUMENTS) }
      end

      private

      def unconditional_includes
        super + [{ target_project: [:group] }]
      end

      def project
        nil
      end

      def no_results_possible?(args)
        some_argument_is_empty?(args)
      end
    end
  end
end

Resolvers::MergeRequests::RootResolver.prepend_mod
