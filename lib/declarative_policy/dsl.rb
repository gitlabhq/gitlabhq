module DeclarativePolicy
  # The DSL evaluation context inside rule { ... } blocks.
  # Responsible for creating and combining Rule objects.
  #
  # See Base.rule
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

    def delegate(delegate_name, condition)
      Rule::DelegatedCondition.new(delegate_name, condition)
    end

    def method_missing(m, *a, &b)
      return super unless a.size == 0 && !block_given?

      if @context_class.delegations.key?(m)
        DelegateDsl.new(self, m)
      else
        cond(m.to_sym)
      end
    end
  end

  # Used when the name of a delegate is mentioned in
  # the rule DSL.
  class DelegateDsl
    def initialize(rule_dsl, delegate_name)
      @rule_dsl = rule_dsl
      @delegate_name = delegate_name
    end

    def method_missing(m, *a, &b)
      return super unless a.size == 0 && !block_given?

      @rule_dsl.delegate(@delegate_name, m)
    end
  end

  # The return value of a rule { ... } declaration.
  # Can call back to register rules with the containing
  # Policy class (context_class here). See Base.rule
  #
  # Note that the #policy method just performs an #instance_eval,
  # which is useful for multiple #enable or #prevent callse.
  #
  # Also provides a #method_missing proxy to the context
  # class's class methods, so that helper methods can be
  # defined and used in a #policy { ... } block.
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
