module DeclarativePolicy
  class Runner
    class State
      def initialize
        @enabled = false
        @prevented = false
      end

      def enable!
        @enabled = true
      end

      def enabled?
        @enabled
      end

      def prevent!
        @prevented = true
      end

      def prevented?
        @prevented
      end

      def pass?
        !prevented? && enabled?
      end
    end

    # a Runner contains a list of Steps to be run.
    attr_reader :steps
    def initialize(steps)
      @steps = steps
    end

    # We make sure only to run any given Runner once,
    # and just continue to use the resulting @state
    # that's left behind.
    def cached?
      !!@state
    end

    # used by Rule::Ability. See #steps_by_score
    def score
      return 0 if cached?
      steps.map(&:score).inject(0, :+)
    end

    def merge_runner(other)
      Runner.new(@steps + other.steps)
    end

    # The main entry point, called for making an ability decision.
    # See #run and DeclarativePolicy::Base#can?
    def pass?
      run unless cached?

      @state.pass?
    end

    # see DeclarativePolicy::Base#debug
    def debug(out = $stderr)
      run(out)
    end

    private

    def flatten_steps!
      @steps = @steps.flat_map { |s| s.flattened(@steps) }
    end

    # This method implements the semantic of "one enable and no prevents".
    # It relies on #steps_by_score for the main loop, and updates @state
    # with the result of the step.
    def run(debug = nil)
      @state = State.new

      steps_by_score do |step, score|
        passed = nil
        case step.action
        when :enable then
          # we only check :enable actions if they have a chance of
          # changing the outcome - if no other rule has enabled or
          # prevented.
          unless @state.enabled? || @state.prevented?
            passed = step.pass?
            @state.enable! if passed
          end

          debug << inspect_step(step, score, passed) if debug
        when :prevent then
          # we only check :prevent actions if the state hasn't already
          # been prevented.
          unless @state.prevented?
            passed = step.pass?
            if passed
              @state.prevent!
              return unless debug
            end
          end

          debug << inspect_step(step, score, passed) if debug
        else raise "invalid action #{step.action.inspect}"
        end
      end

      @state
    end

    # This is the core spot where all those `#score` methods matter.
    # It is critcal for performance to run steps in the correct order,
    # so that we don't compute expensive conditions (potentially n times
    # if we're called on, say, a large list of users).
    #
    # In order to determine the cheapest step to run next, we rely on
    # Step#score, which returns a numerical rating of how expensive
    # it would be to calculate - the lower the better. It would be
    # easy enough to statically sort by these scores, but we can do
    # a little better - the scores are cache-aware (conditions that
    # are already in the cache have score 0), which means that running
    # a step can actually change the scores of other steps.
    #
    # So! The way we sort here involves re-scoring at every step. This
    # is by necessity quadratic, but most of the time the number of steps
    # will be low. But just in case, if the number of steps exceeds 50,
    # we print a warning and fall back to a static sort.
    #
    # For each step, we yield the step object along with the computed score
    # for debugging purposes.
    def steps_by_score(&b)
      flatten_steps!

      if @steps.size > 50
        warn "DeclarativePolicy: large number of steps (#{steps.size}), falling back to static sort"

        @steps.map { |s| [s.score, s] }.sort_by { |(score, _)| score }.each do |(score, step)|
          yield step, score
        end

        return
      end

      steps = Set.new(@steps)
      remaining_enablers = steps.count { |s| s.enable? }

      loop do
        return if steps.empty?

        # if the permission hasn't yet been enabled and we only have
        # prevent steps left, we short-circuit the state here
        @state.prevent! if !@state.enabled? && remaining_enablers == 0

        lowest_score = Float::INFINITY
        next_step = nil

        steps.each do |step|
          score = step.score
          if score < lowest_score
            next_step = step
            lowest_score = score
          end
        end

        steps.delete(next_step)

        remaining_enablers -= 1 if next_step.enable?

        yield next_step, lowest_score
      end
    end

    # Formatter for debugging output.
    def inspect_step(step, original_score, passed)
      symbol =
        case passed
        when true then '+'
        when false then '-'
        when nil then ' '
        end

      "#{symbol} [#{original_score.to_i}] #{step.repr}\n"
    end
  end
end
