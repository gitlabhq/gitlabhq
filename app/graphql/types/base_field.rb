# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    include GitlabStyleDeprecations

    argument_class ::Types::BaseArgument

    DEFAULT_COMPLEXITY = 1

    attr_reader :deprecation, :doc_reference

    def initialize(**kwargs, &block)
      @calls_gitaly = !!kwargs.delete(:calls_gitaly)
      @doc_reference = kwargs.delete(:see)
      @constant_complexity = kwargs[:complexity].is_a?(Integer) && kwargs[:complexity] > 0
      @requires_argument = !!kwargs.delete(:requires_argument)
      @authorize = Array.wrap(kwargs.delete(:authorize))
      kwargs[:complexity] = field_complexity(kwargs[:resolver_class], kwargs[:complexity])
      @feature_flag = kwargs[:feature_flag]
      kwargs = check_feature_flag(kwargs)
      @deprecation = gitlab_deprecation(kwargs)

      super(**kwargs, &block)

      # We want to avoid the overhead of this in prod
      extension ::Gitlab::Graphql::CallsGitaly::FieldExtension if Gitlab.dev_or_test_env?
      extension ::Gitlab::Graphql::Present::FieldExtension
      extension ::Gitlab::Graphql::Authorize::ConnectionFilterExtension
    end

    def may_call_gitaly?
      @constant_complexity || @calls_gitaly
    end

    def requires_argument?
      @requires_argument || arguments.values.any? { |argument| argument.type.non_null? }
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

    def base_complexity
      complexity = DEFAULT_COMPLEXITY
      complexity += 1 if calls_gitaly?
      complexity
    end

    def calls_gitaly?
      @calls_gitaly
    end

    def constant_complexity?
      @constant_complexity
    end

    def visible?(context)
      return false if feature_flag.present? && !Feature.enabled?(feature_flag, default_enabled: :yaml)

      super
    end

    private

    attr_reader :feature_flag

    def field_authorized?(object, ctx)
      authorization.ok?(object, ctx[:current_user])
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
      @authorization ||= ::Gitlab::Graphql::Authorize::ObjectAuthorization.new(@authorize)
    end

    def feature_documentation_message(key, description)
      "#{description} Available only when feature flag `#{key}` is enabled."
    end

    def check_feature_flag(args)
      ff = args.delete(:feature_flag)
      return args unless ff.present?

      args[:description] = feature_documentation_message(ff, args[:description])

      args
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
        complexity += complexity * connection_complexity_multiplier(ctx, args)

        complexity.to_i
      end
    end

    def connection_complexity_multiplier(ctx, args)
      # Resolvers may add extra complexity depending on number of items being loaded.
      field_defn = to_graphql
      return 0 unless field_defn.connection?

      page_size   = field_defn.connection_max_page_size || ctx.schema.default_max_page_size
      limit_value = [args[:first], args[:last], page_size].compact.min
      multiplier  = resolver&.try(:complexity_multiplier, args).to_f
      limit_value * multiplier
    end
  end
end
