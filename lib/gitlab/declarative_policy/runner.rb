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

    attr_reader :steps
    def initialize(steps)
      @steps = steps.flat_map { |s| s.flattened(steps) }
    end

    def cached?
      !!@state
    end

    def score
      return 0 if cached?
      steps.map(&:score).inject(0, :+)
    end

    def merge_runner(other)
      Runner.new(@steps + other.steps)
    end

    def pass?
      run unless cached?

      @state.pass?
    end

    def debug(out = $stderr)
      run(out)
    end

    private

    def run(debug = nil)
      @state = State.new

      steps_by_score do |step, score|
        passed = nil
        case step.action
        when :enable then
          unless @state.enabled? || @state.prevented?
            passed = step.pass?
            @state.enable! if passed
          end

          debug << inspect_step(step, score, passed) if debug
        when :prevent then
          unless @state.prevented?
            passed = step.pass?
            @state.prevent! if passed
          end

          debug << inspect_step(step, score, passed) if debug
        else raise 'invalid action'
        end
      end

      @state
    end

    def steps_by_score(&b)
      if @steps.size > 50
        warn "DeclarativePolicy: large number of steps (#{steps.size}), falling back to static sort"

        @steps.map { |s| [s.score, s] }.sort_by { |(score, _)| score }.each do |(score, step)|
          yield step, score
        end

        return
      end

      steps = Set.new(@steps)

      # NOTE: this is quadratic, but we've verified that the
      # number of steps is at most 50, and with this approach we
      # re-score as we go, eliminating the need for some expensive
      # conditions to be calcuated.
      loop do
        return if steps.empty?

        # if the permission hasn't yet been enabled and we only have
        # prevent steps left, we short-circuit the state here
        @state.prevent! if !@state.enabled? && steps.all? { |s| s.action == :prevent }

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

        yield next_step, lowest_score
      end
    end

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
