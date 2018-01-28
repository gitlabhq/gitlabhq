module DeclarativePolicy
  module Rule
    # A Rule is the object that results from the `rule` declaration,
    # usually built using the DSL in `RuleDsl`. It is a basic logical
    # combination of building blocks, and is capable of deciding,
    # given a context (instance of DeclarativePolicy::Base) whether it
    # passes or not. Note that this decision doesn't by itself know
    # how that affects the actual ability decision - for that, a
    # `Step` is used.
    class Base
      def self.make(*a)
        new(*a).simplify
      end

      # true or false whether this rule passes.
      # `context` is a policy - an instance of
      # DeclarativePolicy::Base.
      def pass?(context)
        raise 'abstract'
      end

      # same as #pass? except refuses to do any I/O,
      # returning nil if the result is not yet cached.
      # used for accurately scoring And/Or
      def cached_pass?(context)
        raise 'abstract'
      end

      # abstractly, how long would it take to compute
      # this rule? lower-scored rules are tried first.
      def score(context)
        raise 'abstract'
      end

      # unwrap double negatives and nested and/or
      def simplify
        self
      end

      # convenience combination methods
      def or(other)
        Or.make([self, other])
      end

      def and(other)
        And.make([self, other])
      end

      def negate
        Not.make(self)
      end

      alias_method :|, :or
      alias_method :&, :and
      alias_method :~@, :negate

      def inspect
        "#<Rule #{repr}>"
      end
    end

    # A rule that checks a condition. This is the
    # type of rule that results from a basic bareword
    # in the rule dsl (see RuleDsl#method_missing).
    class Condition < Base
      def initialize(name)
        @name = name
      end

      # we delegate scoring to the condition. See
      # ManifestCondition#score.
      def score(context)
        context.condition(@name).score
      end

      # Let the ManifestCondition from the context
      # decide whether we pass.
      def pass?(context)
        context.condition(@name).pass?
      end

      # returns nil unless it's already cached
      def cached_pass?(context)
        condition = context.condition(@name)
        return nil unless condition.cached?

        condition.pass?
      end

      def description(context)
        context.class.conditions[@name].description
      end

      def repr
        @name.to_s
      end
    end

    # A rule constructed from DelegateDsl - using a condition from a
    # delegated policy.
    class DelegatedCondition < Base
      # Internal use only - this is rescued each time it's raised.
      MissingDelegate = Class.new(StandardError)

      def initialize(delegate_name, name)
        @delegate_name = delegate_name
        @name = name
      end

      def delegated_context(context)
        policy = context.delegated_policies[@delegate_name]
        raise MissingDelegate if policy.nil?

        policy
      end

      def score(context)
        delegated_context(context).condition(@name).score
      rescue MissingDelegate
        0
      end

      def cached_pass?(context)
        condition = delegated_context(context).condition(@name)
        return nil unless condition.cached?

        condition.pass?
      rescue MissingDelegate
        false
      end

      def pass?(context)
        delegated_context(context).condition(@name).pass?
      rescue MissingDelegate
        false
      end

      def repr
        "#{@delegate_name}.#{@name}"
      end
    end

    # A rule constructed from RuleDsl#can?. Computes a different ability
    # on the same subject.
    class Ability < Base
      attr_reader :ability
      def initialize(ability)
        @ability = ability
      end

      # We ask the ability's runner for a score
      def score(context)
        context.runner(@ability).score
      end

      def pass?(context)
        context.allowed?(@ability)
      end

      def cached_pass?(context)
        runner = context.runner(@ability)
        return nil unless runner.cached?

        runner.pass?
      end

      def description(context)
        "User can #{@ability.inspect}"
      end

      def repr
        "can?(#{@ability.inspect})"
      end
    end

    # Logical `and`, containing a list of rules. Only passes
    # if all of them do.
    class And < Base
      attr_reader :rules
      def initialize(rules)
        @rules = rules
      end

      def simplify
        simplified_rules = @rules.flat_map do |rule|
          simplified = rule.simplify
          case simplified
          when And then simplified.rules
          else [simplified]
          end
        end

        And.new(simplified_rules)
      end

      def score(context)
        return 0 unless cached_pass?(context).nil?

        # note that cached rules will have score 0 anyways.
        @rules.map { |r| r.score(context) }.inject(0, :+)
      end

      def pass?(context)
        # try to find a cached answer before
        # checking in order
        cached = cached_pass?(context)
        return cached unless cached.nil?

        @rules.all? { |r| r.pass?(context) }
      end

      def cached_pass?(context)
        @rules.each do |rule|
          pass = rule.cached_pass?(context)

          return pass if pass.nil? || pass == false
        end

        true
      end

      def repr
        "all?(#{rules.map(&:repr).join(', ')})"
      end
    end

    # Logical `or`. Mirrors And.
    class Or < Base
      attr_reader :rules
      def initialize(rules)
        @rules = rules
      end

      def pass?(context)
        cached = cached_pass?(context)
        return cached unless cached.nil?

        @rules.any? { |r| r.pass?(context) }
      end

      def simplify
        simplified_rules = @rules.flat_map do |rule|
          simplified = rule.simplify
          case simplified
          when Or then simplified.rules
          else [simplified]
          end
        end

        Or.new(simplified_rules)
      end

      def cached_pass?(context)
        @rules.each do |rule|
          pass = rule.cached_pass?(context)

          return pass if pass.nil? || pass == true
        end

        false
      end

      def score(context)
        return 0 unless cached_pass?(context).nil?

        @rules.map { |r| r.score(context) }.inject(0, :+)
      end

      def repr
        "any?(#{@rules.map(&:repr).join(', ')})"
      end
    end

    class Not < Base
      attr_reader :rule
      def initialize(rule)
        @rule = rule
      end

      def simplify
        case @rule
        when And then Or.new(@rule.rules.map(&:negate)).simplify
        when Or then And.new(@rule.rules.map(&:negate)).simplify
        when Not then @rule.rule.simplify
        else Not.new(@rule.simplify)
        end
      end

      def pass?(context)
        !@rule.pass?(context)
      end

      def cached_pass?(context)
        case @rule.cached_pass?(context)
        when nil then nil
        when true then false
        when false then true
        end
      end

      def score(context)
        @rule.score(context)
      end

      def repr
        "~#{@rule.repr}"
      end
    end
  end
end
