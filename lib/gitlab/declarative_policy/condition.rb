module DeclarativePolicy
  class Condition
    attr_reader :name, :description, :scope
    attr_reader :manual_score
    attr_reader :context_key
    def initialize(name, description, opts = {}, &compute)
      @name = name
      @description = description
      @compute = compute
      @scope = opts.fetch(:scope, :normal)
      @context_key = opts[:context_key]
      @manual_score = opts.fetch(:score, nil)
    end

    def pass?(context)
      cache(context) { !!context.instance_eval(&@compute) }
    end

    def compute(context)
      !!context.instance_eval(&@compute)
    end

    def key
      "#{@context_key}/#{@name}"
    end
  end

  class ManifestCondition
    def initialize(condition, context)
      @condition = condition
      @context = context
    end

    def pass?
      @context.cache(cache_key) { @condition.compute(@context) }
    end

    def cached?
      @context.cached?(cache_key)
    end

    def score
      return 0 if cached?
      return @condition.manual_score if @condition.manual_score
      return 2 if  @condition.scope == :global
      return 16 if @condition.scope == :normal
      return 4 if DeclarativePolicy.preferred_scope == @condition.scope

      8
    end

    private

    def cache_key
      case @condition.scope
      when :normal  then "/dp/ability/#{@condition.key}/#{user_key},#{subject_key}"
      when :user    then "/dp/ability/#{@condition.key}/#{user_key}"
      when :subject then "/dp/ability/#{@condition.key}/#{subject_key}"
      when :global  then "/dp/ability/#{@condition.key}"
      else raise 'invalid scope'
      end
    end

    def user_key
      Cache.user_key(@context.user)
    end

    def subject_key
      Cache.subject_key(@context.subject)
    end
  end
end
