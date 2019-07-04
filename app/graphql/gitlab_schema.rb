# frozen_string_literal: true

class GitlabSchema < GraphQL::Schema
  # Currently an IntrospectionQuery has a complexity of 179.
  # These values will evolve over time.
  DEFAULT_MAX_COMPLEXITY   = 200
  AUTHENTICATED_COMPLEXITY = 250
  ADMIN_COMPLEXITY         = 300

  DEFAULT_MAX_DEPTH = 15
  AUTHENTICATED_MAX_DEPTH = 20

  use BatchLoader::GraphQL
  use Gitlab::Graphql::Authorize
  use Gitlab::Graphql::Present
  use Gitlab::Graphql::CallsGitaly
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

    def id_from_object(object)
      unless object.respond_to?(:to_global_id)
        # This is an error in our schema and needs to be solved. So raise a
        # more meaningfull error message
        raise "#{object} does not implement `to_global_id`. "\
              "Include `GlobalID::Identification` into `#{object.class}"
      end

      object.to_global_id
    end

    def object_from_id(global_id)
      gid = GlobalID.parse(global_id)

      unless gid
        raise Gitlab::Graphql::Errors::ArgumentError, "#{global_id} is not a valid GitLab id."
      end

      if gid.model_class < ApplicationRecord
        Gitlab::Graphql::Loaders::BatchModelLoader.new(gid.model_class, gid.model_id).find
      elsif gid.model_class.respond_to?(:lazy_find)
        gid.model_class.lazy_find(gid.model_id)
      else
        gid.find
      end
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
