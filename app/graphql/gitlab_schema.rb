# frozen_string_literal: true

class GitlabSchema < GraphQL::Schema
  DEFAULT_MAX_COMPLEXITY = 200
  AUTHENTICATED_MAX_COMPLEXITY = 250
  ADMIN_MAX_COMPLEXITY = 300
  # Current GraphiQL introspection query has complexity of 217.
  # As we cache this specific query we allow it to have a higher complexity.
  INTROSPECTION_MAX_COMPLEXITY = 217

  DEFAULT_MAX_DEPTH = 15
  AUTHENTICATED_MAX_DEPTH = 20

  trace_with Gitlab::Graphql::Tracers::InstrumentationTracer

  use Gitlab::Graphql::Subscriptions::ActionCableWithLoadBalancing
  use BatchLoader::GraphQL
  use Gitlab::Graphql::Pagination::Connections
  use Gitlab::Graphql::Timeout, max_seconds: Gitlab.config.gitlab.graphql_timeout

  query_analyzer Gitlab::Graphql::QueryAnalyzers::AST::LoggerAnalyzer
  query_analyzer Gitlab::Graphql::QueryAnalyzers::AST::RecursionAnalyzer

  query Types::QueryType
  mutation Types::MutationType
  subscription Types::SubscriptionType

  default_max_page_size 100

  validate_max_errors 5
  validate_timeout 0.2.seconds

  lazy_resolve ::Gitlab::Graphql::Lazy, :force

  class << self
    def multiplex(queries, **kwargs)
      kwargs[:max_complexity] ||= max_query_complexity(kwargs[:context]) unless kwargs.key?(:max_complexity)

      queries.each do |query|
        query[:max_complexity] ||= max_query_complexity(query[:context]) unless query.key?(:max_complexity)
        query[:max_depth] = max_query_depth(query[:context]) unless query.key?(:max_depth)
      end

      super(queries, **kwargs)
    end

    def get_type(type_name, *other_args)
      type_name = Gitlab::GlobalId::Deprecations.apply_to_graphql_name(type_name)
      type_name = Gitlab::Graphql::TypeNameDeprecations.apply_to_graphql_name(type_name)

      super(type_name, *other_args)
    end

    def id_from_object(object, _type = nil, _ctx = nil)
      unless object.respond_to?(:to_global_id)
        # This is an error in our schema and needs to be solved. So raise a
        # more meaningful error message
        raise "#{object} does not implement `to_global_id`. " \
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

    def resolve_type(type, object, ctx = :__undefined__)
      return if type.respond_to?(:assignable?) && !type.assignable?(object)

      if type.kind.object?
        type
      else
        super
      end
    end

    # Find an object by looking it up from its 'GlobalID'.
    #
    # * For `ApplicationRecord`s, this is equivalent to
    #   `global_id.model_class.find(gid.model_id)`, but more efficient.
    # * For classes that implement `.lazy_find(global_id)`, this class method
    #   will be called.
    # * All other classes will use `GlobalID#find`
    def find_by_gid(gid)
      return unless gid

      if gid.model_class < ApplicationRecord
        Gitlab::Graphql::Loaders::BatchModelLoader.new(gid.model_class, gid.model_id).find
      elsif gid.model_class.respond_to?(:lazy_find)
        gid.model_class.lazy_find(gid.model_id)
      else
        begin
          gid.find
        # other if conditions return nil when the record is not found
        rescue ActiveRecord::RecordNotFound
          nil
        end
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
    #  * :expected_type [[Class]] - array of the types of object this GlobalID should refer to.
    #
    # e.g.
    #
    # ```
    #   gid = GitlabSchema.parse_gid(my_string, expected_type: ::Project)
    #   project_id = gid.model_id
    #   gid.model_class == ::Project
    # ```
    def parse_gid(global_id, ctx = {})
      expected_types = Array(ctx[:expected_type])
      gid = GlobalID.parse(global_id)

      raise Gitlab::Graphql::Errors::ArgumentError, "#{global_id} is not a valid GitLab ID." unless gid

      if expected_types.any? && expected_types.none? { |type| gid.model_class.ancestors.include?(type) }
        vars = { global_id: global_id, expected_types: expected_types.join(', ') }
        msg = _('%{global_id} is not a valid ID for %{expected_types}.') % vars
        raise Gitlab::Graphql::Errors::ArgumentError, msg
      end

      gid
    end

    # Parse an array of strings to an array of GlobalIDs, raising ArgumentError if there are problems
    # with it.
    # See #parse_gid
    #
    # ```
    #   gids = GitlabSchema.parse_gids(my_array_of_strings, expected_type: ::Project)
    #   project_ids = gids.map(&:model_id)
    #   gids.all? { |gid| gid.model_class == ::Project }
    # ```
    def parse_gids(global_ids, ctx = {})
      global_ids.map { |gid| parse_gid(gid, ctx) }
    end

    def unauthorized_field(error)
      return error.field.if_unauthorized if error.field.respond_to?(:if_unauthorized) && error.field.if_unauthorized

      super
    end

    private

    def max_query_complexity(ctx)
      current_user = ctx&.fetch(:current_user, nil)
      introspection = ctx&.fetch(:introspection, false)

      if current_user&.admin
        ADMIN_MAX_COMPLEXITY
      elsif current_user
        AUTHENTICATED_MAX_COMPLEXITY
      elsif introspection
        INTROSPECTION_MAX_COMPLEXITY
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

  def get_type(type_name)
    type_name = Gitlab::GlobalId::Deprecations.apply_to_graphql_name(type_name)
    type_name = Gitlab::Graphql::TypeNameDeprecations.apply_to_graphql_name(type_name)

    super(type_name)
  end
end

GitlabSchema.prepend_mod_with('GitlabSchema')
