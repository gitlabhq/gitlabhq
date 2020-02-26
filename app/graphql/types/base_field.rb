# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    prepend Gitlab::Graphql::Authorize

    DEFAULT_COMPLEXITY = 1

    def initialize(*args, **kwargs, &block)
      @calls_gitaly = !!kwargs.delete(:calls_gitaly)
      @constant_complexity = !!kwargs[:complexity]
      kwargs[:complexity] = field_complexity(kwargs[:resolver_class], kwargs[:complexity])
      @feature_flag = kwargs[:feature_flag]
      kwargs = check_feature_flag(kwargs)

      super(*args, **kwargs, &block)
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
      "#{description}. Available only when feature flag #{key} is enabled."
    end

    def check_feature_flag(args)
      args[:description] = feature_documentation_message(args[:feature_flag], args[:description]) if args[:feature_flag].present?
      args.delete(:feature_flag)

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
        next base_complexity unless resolver_complexity_enabled?(ctx)

        # Resolvers may add extra complexity depending on used arguments
        complexity = child_complexity + self.resolver&.try(:resolver_complexity, args, child_complexity: child_complexity).to_i
        complexity += 1 if calls_gitaly?
        complexity += complexity * connection_complexity_multiplier(ctx, args)

        complexity.to_i
      end
    end

    def resolver_complexity_enabled?(ctx)
      ctx.fetch(:graphql_resolver_complexity_flag) { |key| ctx[key] = Feature.enabled?(:graphql_resolver_complexity) }
    end

    def connection_complexity_multiplier(ctx, args)
      # Resolvers may add extra complexity depending on number of items being loaded.
      field_defn = to_graphql
      return 0 unless field_defn.connection?

      page_size   = field_defn.connection_max_page_size || ctx.schema.default_max_page_size
      limit_value = [args[:first], args[:last], page_size].compact.min
      multiplier  = self.resolver&.try(:complexity_multiplier, args).to_f
      limit_value * multiplier
    end
  end
end
