module DeclarativePolicy
  # Used when the name of a delegate is mentioned in
  # the rule DSL.
  class DelegateDsl
    def initialize(rule_dsl, delegate_name)
      @rule_dsl = rule_dsl
      @delegate_name = delegate_name
    end

    def method_missing(m, *a, &b)
      return super unless a.empty? && !block_given?

      @rule_dsl.delegate(@delegate_name, m)
    end
  end
end
