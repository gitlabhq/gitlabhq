# frozen_string_literal: true

module Resolvers
  module Repositories
    class CommitsResolver < BaseResolver
      type Types::Repositories::CommitType.connection_type, null: true

      argument :ref, GraphQL::Types::String,
        required: true,
        description: 'Branch or tag to search for commits.'

      argument :query, Types::UntrustedRegexp,
        required: false,
        description: 'Regular expression to filter the commits.'

      argument :author, GraphQL::Types::String,
        required: false,
        description: 'Name or email of the author.'

      argument :committed_before, Types::TimeType,
        required: false,
        description: 'Commits created before an ISO8601 formatted time or date.'

      argument :committed_after, Types::TimeType,
        required: false,
        description: 'Commits created after an ISO8601 formatted time or date.'

      argument :first, GraphQL::Types::Int,
        description: 'Returns the first _n_ elements from the list.',
        required: false

      argument :after, GraphQL::Types::String,
        description: 'Returns the elements in the list that come after the specified cursor.',
        required: false

      calls_gitaly!

      alias_method :repository, :object

      def resolve(**arguments)
        commits = repository.list_commits(**list_commits_arguments(arguments.dup)).presence&.commits || []

        Gitlab::Graphql::ExternallyPaginatedArray.new(*page_info_cursors(commits), *commits)
      rescue Gitlab::Git::CommandError => e
        raise Gitlab::Graphql::Errors::BaseError.new(
          "ListCommits: Gitlab::Git::CommandError",
          extensions: { code: e.code, gitaly_code: e.status, service: e.service }
        )
      end

      private

      def list_commits_arguments(arguments)
        limit = [arguments.delete(:first), field.max_page_size || context.schema.default_max_page_size].compact.min # rubocop:disable Graphql/Descriptions -- This is incorrectly flagging `field`. We should ensure that there's nothing before `field` in the cop

        page_token = arguments.delete(:after)

        arguments[:pagination_params] = {}.tap do |pagination_params|
          pagination_params[:limit] = limit if limit
          pagination_params[:page_token] = Base64.decode64(page_token) if page_token
        end

        arguments
      end

      # Each cursor is a base64 encoded SHA value. The previous_cursor is
      # generated from the first commit in the list and the next_cursor is
      # generated from the last commit in the list.
      #
      # `commits` could be:
      # 1. [] - an empty list.
      # 2. [Commit(#1)] - a list with a single item.
      # 3. [Commit(#1), ..., Commit(#15)] - a list with multiple items.
      #
      # Returns => [previous_cursor, next_cursor]
      # 1. [nil, nil]
      # 2. [SHA#1, SHA#1]
      # 3. [SHA#1, SHA#15]
      def page_info_cursors(commits)
        return [nil, nil] if commits.empty?
        return Array.new(2, encode_token(commits.first.sha)) if commits.length == 1

        [encode_token(commits.first.sha), encode_token(commits.last.sha)]
      end

      def encode_token(sha)
        Base64.encode64(sha)
      end
    end
  end
end
