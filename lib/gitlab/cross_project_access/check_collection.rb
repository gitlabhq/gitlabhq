module Gitlab
  class CrossProjectAccess
    class CheckCollection
      attr_reader :checks

      def initialize
        @checks = []
      end

      def add_collection(collection)
        @checks |= collection.checks
      end

      def add_check(check)
        @checks << check
      end

      def should_run?(object)
        skips, runs = arranged_checks

        # If one rule tells us to skip, we skip the cross project check
        return false if skips.any? { |check| check.should_skip?(object) }

        # If the rule isn't skipped, we run it if any of the checks says we
        # should run
        runs.any? { |check| check.should_run?(object) }
      end

      def arranged_checks
        return [@skips, @runs] if @skips && @runs

        @skips = []
        @runs = []

        @checks.each do |check|
          if check.skip
            @skips << check
          else
            @runs << check
          end
        end

        [@skips, @runs]
      end
    end
  end
end
