module DeclarativePolicy
  # This object represents one step in the runtime decision of whether
  # an ability is allowed. It contains a Rule and a context (instance
  # of DeclarativePolicy::Base), which contains the user, the subject,
  # and the cache. It also contains an "action", which is the symbol
  # :prevent or :enable.
  class Step
    attr_reader :context, :rule, :action
    def initialize(context, rule, action)
      @context = context
      @rule = rule
      @action = action
    end

    # In the flattening process, duplicate steps may be generated in the
    # same rule. This allows us to eliminate those (see Runner#steps_by_score
    # and note its use of a Set)
    def ==(other)
      @context == other.context && @rule == other.rule && @action == other.action
    end

    # In the runner, steps are sorted dynamically by score, so that
    # we are sure to compute them in close to the optimal order.
    #
    # See also Rule#score, ManifestCondition#score, and Runner#steps_by_score.
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

    def with_action(action)
      Step.new(@context, @rule, action)
    end

    def enable?
      @action == :enable
    end

    def prevent?
      @action == :prevent
    end

    # This rather complex method allows us to split rules into parts so that
    # they can be sorted independently for better optimization
    def flattened(roots)
      case @rule
      when Rule::Or
        # A single `Or` step is the same as each of its elements as separate steps
        @rule.rules.flat_map { |r| Step.new(@context, r, @action).flattened(roots) }
      when Rule::Ability
        # This looks like a weird micro-optimization but it buys us quite a lot
        # in some cases. If we depend on an Ability (i.e. a `can?(...)` rule),
        # and that ability *only* has :enable actions (modulo some actions that
        # we already have taken care of), then its rules can be safely inlined.
        steps = @context.runner(@rule.ability).steps.reject { |s| roots.include?(s) }

        if steps.all?(&:enable?)
          # in the case that we are a :prevent step, each inlined step becomes
          # an independent :prevent, even though it was an :enable in its initial
          # context.
          steps.map! { |s| s.with_action(:prevent) } if prevent?

          steps.flat_map { |s| s.flattened(roots) }
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
