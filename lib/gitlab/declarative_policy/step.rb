module DeclarativePolicy
  class Step
    attr_reader :context, :rule, :action
    def initialize(context, rule, action)
      @context = context
      @rule = rule
      @action = action
    end

    def ==(other)
      @context == other.context && @rule == other.rule && @action == other.action
    end

    def score
      # we slightly prefer the preventative actions
      # since they are more likely to short-circuit
      case @action
      when :prevent
        @rule.score(@context) * (7.0 / 8)
      when :enable
        @rule.score(@context)
      end
    end

    # any rule that has an Or on the outside can be split into individual
    # steps for better optimization
    def flattened(roots)
      case @rule
      when Rule::Or
        @rule.rules.flat_map { |r| Step.new(@context, r, @action).flattened(roots) }
      when Rule::Ability
        steps = @context.runner(@rule.ability).steps
        if steps.all? { |s| s.action == :enable || roots.include?(s) }
          new_steps =
            case @action
            when :enable
              steps
            when :prevent
              steps.map { |s| Step.new(s.context, s.rule, :prevent) }
            end

          new_steps.select { |s| s.action == :enable }.flat_map { |s| s.flattened(roots) }
        else
          [self]
        end
      else
        [self]
      end
    end

    def pass?
      @rule.pass?(@context)
    end

    def repr
      "#{@action} when #{@rule.repr} (#{@context.repr})"
    end
  end
end
