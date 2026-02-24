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

      calls_gitaly!

      alias_method :repository, :object

      def resolve(**arguments)
        first = arguments.delete(:first)
        page_token = arguments.delete(:after)
        limit = compute_limit(first)

        return empty_result if limit <= 0

        response = repository.list_commits(**list_commits_arguments(arguments, limit, page_token))
        commits = response.commits.to_a

        # Determine if there's a next page by checking if we got more commits than requested
        # We request limit + 1 to detect this
        has_next_page = limit && commits.size > limit
        commits = commits.first(limit) if has_next_page

        # FIX: use `response.next_cursor` instead of calculating commit manually
        end_cursor = Base64.encode64(commits.last.sha) if has_next_page

        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, end_cursor, *commits, has_next_page: has_next_page)
      rescue Gitlab::Git::CommandError => e
        raise Gitlab::Graphql::Errors::BaseError.new(
          "ListCommits: Gitlab::Git::CommandError",
          extensions: { code: e.code, gitaly_code: e.status, service: e.service }
        )
      end

      private

      # Checks the user defined limit, the field's max page size or the schemas
      # default, and returns the most restrictive limit.
      def compute_limit(first)
        # rubocop:disable Graphql/Descriptions -- This is incorrectly flagging `field`. We should ensure that there's nothing before `field` in the cop
        [first, field.max_page_size || context.schema.default_max_page_size].compact.min
        # rubocop:enable Graphql/Descriptions
      end

      def list_commits_arguments(arguments, limit, page_token)
        arguments[:pagination_params] = {}.tap do |pagination_params|
          # Request one extra commit to determine if there's a next page
          pagination_params[:limit] = limit + 1
          pagination_params[:page_token] = Base64.decode64(page_token) if page_token
        end

        arguments
      end

      def empty_result
        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, nil, has_next_page: false)
      end
    end
  end
end
