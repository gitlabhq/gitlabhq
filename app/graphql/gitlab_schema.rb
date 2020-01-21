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
  query_analyzer Gitlab::Graphql::QueryAnalyzers::RecursionAnalyzer.new

  max_complexity DEFAULT_MAX_COMPLEXITY
  max_depth DEFAULT_MAX_DEPTH

  query Types::QueryType
  mutation Types::MutationType

  default_max_page_size 100

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

    def id_from_object(object, _type = nil, _ctx = nil)
      unless object.respond_to?(:to_global_id)
        # This is an error in our schema and needs to be solved. So raise a
        # more meaningful error message
        raise "#{object} does not implement `to_global_id`. "\
              "Include `GlobalID::Identification` into `#{object.class}"
      end

      object.to_global_id
    end

    # Find an object by looking it up from its global ID, passed as a string.
    #
    # This is the composition of 'parse_gid' and 'find_by_gid', see these
    # methods for further documentation.
    def object_from_id(global_id, ctx = {})
      gid = parse_gid(global_id, ctx)

      find_by_gid(gid)
    end

    # Find an object by looking it up from its 'GlobalID'.
    #
    # * For `ApplicationRecord`s, this is equivalent to
    #   `global_id.model_class.find(gid.model_id)`, but more efficient.
    # * For classes that implement `.lazy_find(global_id)`, this class method
    #   will be called.
    # * All other classes will use `GlobalID#find`
    def find_by_gid(gid)
      if gid.model_class < ApplicationRecord
        Gitlab::Graphql::Loaders::BatchModelLoader.new(gid.model_class, gid.model_id).find
      elsif gid.model_class.respond_to?(:lazy_find)
        gid.model_class.lazy_find(gid.model_id)
      else
        gid.find
      end
    end

    # Parse a string to a GlobalID, raising ArgumentError if there are problems
    # with it.
    #
    # Problems that may occur:
    #  * it may not be syntactically valid
    #  * it may not match the expected type (see below)
    #
    # Options:
    #  * :expected_type [Class] - the type of object this GlobalID should refer to.
    #
    # e.g.
    #
    # ```
    #   gid = GitlabSchema.parse_gid(my_string, expected_type: ::Project)
    #   project_id = gid.model_id
    #   gid.model_class == ::Project
    # ```
    def parse_gid(global_id, ctx = {})
      expected_type = ctx[:expected_type]
      gid = GlobalID.parse(global_id)

      raise Gitlab::Graphql::Errors::ArgumentError, "#{global_id} is not a valid GitLab id." unless gid

      if expected_type && !gid.model_class.ancestors.include?(expected_type)
        vars = { global_id: global_id, expected_type: expected_type }
        msg = _('%{global_id} is not a valid id for %{expected_type}.') % vars
        raise Gitlab::Graphql::Errors::ArgumentError, msg
      end

      gid
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
