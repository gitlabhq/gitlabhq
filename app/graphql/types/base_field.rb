# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    prepend Gitlab::Graphql::Authorize

    attr_reader :calls_gitaly

    DEFAULT_COMPLEXITY = 1

    def initialize(*args, **kwargs, &block)
      @calls_gitaly = !!kwargs.delete(:calls_gitaly)
      kwargs[:complexity] ||= field_complexity(kwargs[:resolver_class])

      super(*args, **kwargs, &block)
    end

    def base_complexity
      complexity = DEFAULT_COMPLEXITY
      complexity += 1 if @calls_gitaly
      complexity
    end

    private

    def field_complexity(resolver_class)
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
        complexity = child_complexity + self.resolver&.try(:resolver_complexity, args, child_complexity: child_complexity).to_i

        field_defn = to_graphql

        if field_defn.connection?
          # Resolvers may add extra complexity depending on number of items being loaded.
          page_size   = field_defn.connection_max_page_size || ctx.schema.default_max_page_size
          limit_value = [args[:first], args[:last], page_size].compact.min
          multiplier  = self.resolver&.try(:complexity_multiplier, args).to_f
          complexity += complexity * limit_value * multiplier
        end

        complexity.to_i
      end
    end

    def calls_gitaly_check
      # Will inform you if :calls_gitaly should be true or false based on the number of Gitaly calls
      # involved with the request.
      if @calls_gitaly && Gitlab::GitalyClient.get_request_count == 0
        raise "Gitaly is called for field '#{name}' - please add `calls_gitaly: true` to the field declaration"
      elsif !@calls_gitaly && Gitlab::GitalyClient.get_request_count > 0
        raise "Gitaly not called for field '#{name}' - please remove `calls_gitaly: true` from the field declaration"
      end
    rescue => e
      Gitlab::Sentry.track_exception(e)
    end
  end
end
