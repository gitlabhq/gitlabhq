module DeclarativePolicy
  class RuleDsl
    def initialize(context_class)
      @context_class = context_class
    end

    def can?(ability)
      Rule::Ability.new(ability)
    end

    def all?(*rules)
      Rule::And.make(rules)
    end

    def any?(*rules)
      Rule::Or.make(rules)
    end

    def none?(*rules)
      ~Rule::Or.new(rules)
    end

    def cond(condition)
      Rule::Condition.new(condition)
    end

    def method_missing(m, *a, &b)
      return super unless a.size == 0 && !block_given?

      cond(m.to_sym)
    end
  end

  class PolicyDsl
    def initialize(context_class, rule)
      @context_class = context_class
      @rule = rule
    end

    def policy(&b)
      instance_eval(&b)
    end

    def enable(*abilities)
      @context_class.enable_when(abilities, @rule)
    end

    def prevent(*abilities)
      @context_class.prevent_when(abilities, @rule)
    end

    def prevent_all
      @context_class.prevent_all_when(@rule)
    end

    def method_missing(m, *a, &b)
      return super unless @context_class.respond_to?(m)

      @context_class.__send__(m, *a, &b)
    end

    def respond_to_missing?(m)
      @context_class.respond_to?(m) || super
    end
  end
end
