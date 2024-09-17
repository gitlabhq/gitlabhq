# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    include Gitlab::Graphql::Deprecations
    include Gitlab::Graphql::Authorize::AuthorizeResource

    argument_class ::Types::BaseArgument

    DEFAULT_COMPLEXITY = 1

    attr_reader :doc_reference
    attr_accessor :skip_type_authorization

    def initialize(**kwargs, &block)
      @requires_argument = kwargs.delete(:requires_argument)
      @calls_gitaly = kwargs.delete(:calls_gitaly)
      @doc_reference = kwargs.delete(:see)

      given_complexity = kwargs[:complexity] || kwargs[:resolver_class].try(:complexity)
      @constant_complexity = given_complexity.is_a?(Integer) && given_complexity > 0
      kwargs[:complexity] = field_complexity(kwargs[:resolver_class], given_complexity)

      @authorize = Array.wrap(kwargs.delete(:authorize))
      @skip_type_authorization = Array.wrap(kwargs.delete(:skip_type_authorization))
      @scopes = Array.wrap(kwargs.delete(:scopes) || %i[api read_api])
      after_connection_extensions = kwargs.delete(:late_extensions) || []

      super(**kwargs, &block)

      # We want to avoid the overhead of this in prod
      extension ::Gitlab::Graphql::CallsGitaly::FieldExtension if Gitlab.dev_or_test_env?
      extension ::Gitlab::Graphql::Present::FieldExtension
      extension ::Gitlab::Graphql::Authorize::FieldExtension

      after_connection_extensions.each { extension _1 } if after_connection_extensions.any?
    end

    def may_call_gitaly?
      @constant_complexity || calls_gitaly?
    end

    def requires_argument?
      value = @requires_argument.nil? ? @resolver_class.try(:requires_argument?) : @requires_argument
      !!value || arguments.values.any? { |argument| argument.type.non_null? }
    end

    # By default fields authorize against the current object, but that is not how our
    # resolvers work - they use declarative permissions to authorize fields
    # manually (so we make them opt in).
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/300922
    #       (separate out authorize into permissions on the object, and on the
    #       resolved values)
    # We do not support argument authorization in our schema. If/when we do,
    # we should call `super` here, to apply argument authorization checks.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/324647
    def authorized?(object, args, ctx)
      field_authorized?(object, ctx) && resolver_authorized?(object, ctx)
    end

    # This gets called from the gem's `calculate_complexity` method, allowing us
    # to ensure our complexity calculation is used even for connections.
    # This code is actually a copy of the default case in `calculate_complexity`
    # in `lib/graphql/schema/field.rb`
    # (https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/schema/field.rb)
    def complexity_for(child_complexity:, query:, lookahead:)
      defined_complexity = complexity

      case defined_complexity
      when Proc
        arguments = query.arguments_for(lookahead.ast_nodes.first, self)

        if arguments.respond_to?(:keyword_arguments)
          defined_complexity.call(query.context, arguments.keyword_arguments, child_complexity)
        else
          child_complexity
        end
      when Numeric
        defined_complexity + child_complexity
      else
        raise("Invalid complexity: #{defined_complexity.inspect} on #{path} (#{inspect})")
      end
    end

    def base_complexity
      complexity = DEFAULT_COMPLEXITY
      complexity += 1 if calls_gitaly?
      complexity
    end

    def calls_gitaly?
      !!(@calls_gitaly.nil? ? @resolver_class.try(:calls_gitaly?) : @calls_gitaly)
    end

    def constant_complexity?
      @constant_complexity
    end

    private

    def field_authorized?(object, ctx)
      object = object.node if object.is_a?(GraphQL::Pagination::Connection::Edge)

      return true if authorization.ok?(object, ctx[:current_user], scope_validator: ctx[:scope_validator])

      # Fields on MutationType should populate the 'errors' response when authorization fails
      # for consistency with mutation authorization responses.
      # See https://gitlab.com/gitlab-org/gitlab/-/blob/1abb46e235d96f2fa9098d2fb4190143c7c3adb9/app/graphql/mutations/base_mutation.rb#L61-62
      return false unless owner == Types::MutationType

      raise_resource_not_available_error!
    end

    # Historically our resolvers have used declarative permission checks only
    # for _what they resolved_, not the _object they resolved these things from_
    # We preserve these semantics here, and only apply resolver authorization
    # if the resolver has opted in.
    def resolver_authorized?(object, ctx)
      if @resolver_class && @resolver_class.try(:authorizes_object?)
        @resolver_class.authorized?(object, ctx)
      else
        true
      end
    end

    def authorization
      @authorization ||= ::Gitlab::Graphql::Authorize::ObjectAuthorization.new(@authorize, @scopes)
    end

    def field_complexity(resolver_class, current)
      return current if current.present? && current > 0

      if resolver_class
        field_resolver_complexity
      else
        base_complexity
      end
    end

    def field_resolver_complexity
      # Complexity can be either integer or proc. If proc is used then it's
      # called when computing a query complexity and context and query
      # arguments are available for computing complexity.  For resolvers we use
      # proc because we set complexity depending on arguments and number of
      # items which can be loaded.
      proc do |ctx, args, child_complexity|
        # Resolvers may add extra complexity depending on used arguments
        complexity = child_complexity + resolver&.try(
          :resolver_complexity, args, child_complexity: child_complexity
        ).to_i
        complexity += 1 if calls_gitaly?
        ext_conn = resolver&.try(:calculate_ext_conn_complexity)
        complexity += complexity * connection_complexity_multiplier(ctx, args, calculate_ext_conn_complexity: ext_conn)

        complexity.to_i
      end
    end

    def connection_complexity_multiplier(ctx, args, calculate_ext_conn_complexity:)
      # Resolvers may add extra complexity depending on number of items being loaded.
      return 0 if !connection? && !calculate_ext_conn_complexity

      page_size   = max_page_size || ctx.schema.default_max_page_size
      limit_value = [args[:first], args[:last], page_size].compact.min
      multiplier  = resolver&.try(:complexity_multiplier, args).to_f
      limit_value * multiplier
    end
  end
end
