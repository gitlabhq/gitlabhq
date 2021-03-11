# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    prepend Gitlab::Graphql::Authorize
    include GitlabStyleDeprecations

    argument_class ::Types::BaseArgument

    DEFAULT_COMPLEXITY = 1

    def initialize(**kwargs, &block)
      @calls_gitaly = !!kwargs.delete(:calls_gitaly)
      @constant_complexity = kwargs[:complexity].is_a?(Integer) && kwargs[:complexity] > 0
      @requires_argument = !!kwargs.delete(:requires_argument)
      kwargs[:complexity] = field_complexity(kwargs[:resolver_class], kwargs[:complexity])
      @feature_flag = kwargs[:feature_flag]
      kwargs = check_feature_flag(kwargs)
      kwargs = gitlab_deprecation(kwargs)

      super(**kwargs, &block)

      # We want to avoid the overhead of this in prod
      extension ::Gitlab::Graphql::CallsGitaly::FieldExtension if Gitlab.dev_or_test_env?

      extension ::Gitlab::Graphql::Present::FieldExtension
    end

    def may_call_gitaly?
      @constant_complexity || @calls_gitaly
    end

    def requires_argument?
      @requires_argument || arguments.values.any? { |argument| argument.type.non_null? }
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
      return false if feature_flag.present? && !Feature.enabled?(feature_flag)

      super
    end

    private

    attr_reader :feature_flag

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
