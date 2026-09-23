# frozen_string_literal: true

require 'objspace'

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause
        ##
        # Abstract class that defines an interface of a single
        # job rule specification.
        #
        # Used for job's inclusion rules configuration.
        #
        UnknownClauseError = Class.new(StandardError)
        ParseError = Class.new(StandardError)

        # Per-match timeout (seconds) passed to Regexp.new. Bounds a single path match.
        REGEXP_TIMEOUT_SECONDS = 0.05

        # Total time budget (seconds) for evaluating one rule's regexp across all paths.
        REGEXP_TOTAL_TIMEOUT_SECONDS = 2

        # Max regexp length, re-checked at runtime on the expanded pattern since
        # variable expansion can grow it past the config-time limit.
        REGEXP_MAX_LENGTH = 255

        # The \\. branch skips already-escaped characters.
        ESCAPE_OR_ALTERNATION = /\\.|\|/

        # Source length is no guide: 154 bytes can compile to over 2GiB.
        REGEXP_MAX_COMPILED_BYTES = 1.megabyte

        # Onigmo allows a comment between \\g and its argument, so matching \\g< is not enough.
        SUBROUTINE_CALL = /(?<!\\)(?:\\\\)*\\g/

        # Above roughly 7800, Onigmo can unroll a repeat into a program past INT_MAX.
        REPEAT_MAX = 1_000
        REPEAT_BOUND = /(?<!\\)(?:\\\\)*\{\s*(\d+)\s*(?:,\s*(\d+)?\s*)?\}/

        # Compiling an alternation-free copy first keeps invalid patterns away from an
        # Onigmo parser bug in Ruby 3.3 and 3.4, fixed upstream by
        # https://github.com/ruby/ruby/commit/35000ac2
        def self.compile_regexp(pattern, timeout: nil)
          raise RegexpError, 'uses a subroutine call (\\g), which is not allowed' if SUBROUTINE_CALL.match?(pattern)

          reject_large_repeats!(pattern)

          alternation_free = pattern.gsub(ESCAPE_OR_ALTERNATION) { |token| token == '|' ? '\\|' : token }

          probe =
            begin
              Regexp.new(alternation_free)
            rescue RegexpError => e
              # Report the pattern the user wrote, not the copy.
              raise RegexpError, e.message.sub(alternation_free) { pattern }
            end

          # Checked here too, so an oversized program is not built twice.
          check_compiled_size!(probe)
          check_compiled_size!(Regexp.new(pattern, timeout: timeout))
        end

        def self.reject_large_repeats!(pattern)
          pattern.scan(REPEAT_BOUND) do |lower, upper|
            [lower, upper].compact.each do |bound|
              next if bound.to_i <= REPEAT_MAX

              raise RegexpError, "repeats #{bound} times, over the #{REPEAT_MAX} limit: /#{pattern}/"
            end
          end
        end
        private_class_method :reject_large_repeats!

        def self.check_compiled_size!(regexp)
          compiled_bytes = ObjectSpace.memsize_of(regexp)
          return regexp if compiled_bytes <= REGEXP_MAX_COMPILED_BYTES

          raise RegexpError,
            "compiles to #{compiled_bytes} bytes, over the #{REGEXP_MAX_COMPILED_BYTES} byte limit"
        end
        private_class_method :check_compiled_size!

        def self.fabricate(type, value)
          "#{self}::#{type.to_s.camelize}".safe_constantize&.new(value)
        end

        def initialize(spec)
          @spec = spec
        end

        def satisfied_by?(pipeline, context = nil)
          raise NotImplementedError
        end
      end
    end
  end
end
