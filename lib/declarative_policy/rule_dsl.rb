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
      return super unless a.empty? && !block_given?

      if @context_class.delegations.key?(m)
        DelegateDsl.new(self, m)
      else
        cond(m.to_sym)
      end
    end
  end
end
