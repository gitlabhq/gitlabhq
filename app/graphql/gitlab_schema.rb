# frozen_string_literal: true

class GitlabSchema < GraphQL::Schema
  # Currently an IntrospectionQuery has a complexity of 179.
  # These values will evolve over time.
  DEFAULT_MAX_COMPLEXITY   = 200
  AUTHENTICATED_COMPLEXITY = 250
  ADMIN_COMPLEXITY         = 300

  DEFAULT_MAX_DEPTH = 10
  AUTHENTICATED_MAX_DEPTH = 15

  use BatchLoader::GraphQL
  use Gitlab::Graphql::Authorize
  use Gitlab::Graphql::Present
  use Gitlab::Graphql::Connections
  use Gitlab::Graphql::GenericTracing

  query_analyzer Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer.new

  query(Types::QueryType)

  default_max_page_size 100

  max_complexity DEFAULT_MAX_COMPLEXITY
  max_depth DEFAULT_MAX_DEPTH

  mutation(Types::MutationType)

  class << self
    def multiplex(queries, **kwargs)
      kwargs[:max_complexity] ||= max_query_complexity(kwargs[:context])

      queries.each do |query|
        query[:max_depth] = max_query_depth(kwargs[:context])
      end

      super(queries, **kwargs)
    end

    def execute(query_str = nil, **kwargs)
      kwargs[:max_complexity] ||= max_query_complexity(kwargs[:context])
      kwargs[:max_depth] ||= max_query_depth(kwargs[:context])

      super(query_str, **kwargs)
    end

    private

    def max_query_complexity(ctx)
      current_user = ctx&.fetch(:current_user, nil)

      if current_user&.admin
        ADMIN_COMPLEXITY
      elsif current_user
        AUTHENTICATED_COMPLEXITY
      else
        DEFAULT_MAX_COMPLEXITY
      end
    end

    def max_query_depth(ctx)
      current_user = ctx&.fetch(:current_user, nil)

      if current_user
        AUTHENTICATED_MAX_DEPTH
      else
        DEFAULT_MAX_DEPTH
      end
    end
  end
end
