module DeclarativePolicy
  module Rule
    class Base
      def self.make(*a)
        new(*a).simplify
      end

      # whether this rule passes
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

    class Condition < Base
      def initialize(name)
        @name = name
      end

      def score(context)
        context.condition(@name).score
      end

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

    class Ability < Base
      attr_reader :ability
      def initialize(ability)
        @ability = ability
      end

      def score(context)
        context.runner(@ability).score
      end

      def pass?(context)
        context.can?(@ability)
      end

      def cached_pass?(context)
        runner = context.runner(@ability)
        return nil unless runner.cached?
        runner.pass?
      end

      def description(context)
        "User can #{@ablity.inspect}"
      end

      def repr
        "can?(#{@ability.inspect})"
      end
    end

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
        sum = 0

        @rules.each do |rule|
          case rule.cached_pass?(context)
          when nil then sum += rule.score(context)
          when false then return sum
          when true then next
          end
        end

        sum
      end

      def pass?(context)
        @rules.all? { |r| r.pass?(context) }
      end

      def cached_pass?(context)
        @rules.each do |r|
          case r.cached_pass?(context)
          when nil then return nil
          when false then return false
          when true then next
          end
        end

        true
      end

      def repr
        "all?(#{rules.map(&:repr).join(', ')})"
      end
    end

    class Or < Base
      attr_reader :rules
      def initialize(rules)
        @rules = rules
      end

      def pass?(context)
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
        @rules.each do |r|
          case r.cached_pass?(context)
          when nil then return nil
          when true then return true
          when false then next
          end
        end

        false
      end

      def score(context)
        sum = 0
        @rules.each do |rule|
          case rule.cached_pass?(context)
          when nil then sum += rule.score(context)
          when true then return sum
          when false then next
          end
        end

        sum
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
        when Not then @rule.simplify
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
