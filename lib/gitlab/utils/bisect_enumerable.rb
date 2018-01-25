module Gitlab
  module Utils
    module BisectEnumerable
      extend self

      # Bisect an enumerable by using &block as pivot.
      # Return two arrays, depending on the result of the pivot.
      #   [e] -> [[e]: pivot(e) == true, [e]: pivot(e) == false]
      #
      # Example: odd, even = bisect((1..10), &:odd?)
      def bisect(enumerable, &block)
        return [[], []] unless enumerable.any?

        bisect = enumerable.group_by(&block)
        [bisect.fetch(true, []), bisect.fetch(false, [])]
      end
    end
  end
end
