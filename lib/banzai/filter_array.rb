# frozen_string_literal: true

module Banzai
  class FilterArray < Array
    # Insert a value immediately after another value
    #
    # If the preceding value does not exist, the new value is added to the end
    # of the Array.
    def insert_after(after_value, value)
      i = index(after_value) || (length - 1)

      insert(i + 1, value)
    end

    # Insert a value immediately before another value
    #
    # If the succeeding value does not exist, the new value is added to the
    # beginning of the Array.
    def insert_before(before_value, value)
      i = index(before_value) || -1

      if i < 0
        unshift(value)
      else
        insert(i, value)
      end
    end
  end
end
