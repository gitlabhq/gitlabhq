# frozen_string_literal: true

class RefMatcher
  # Maximum pattern length for overlap checks to prevent stack overflow
  # in the recursive patterns_overlap? algorithm.
  MAX_OVERLAP_PATTERN_LENGTH = 255
  STAR_BYTE = '*'.ord

  def initialize(ref_name_or_pattern)
    @ref_name_or_pattern = ref_name_or_pattern
  end

  # Returns all branches/tags (among the given list of refs [`Gitlab::Git::Branch`] or their names [`String`])
  # that match the current protected ref.
  def matching(refs)
    refs.select { |ref| ref.is_a?(String) ? matches?(ref) : matches?(ref.name) }
  end

  # Checks if the protected ref matches the given ref name.
  def matches?(ref_name)
    return false if @ref_name_or_pattern.blank?

    exact_match?(ref_name) || wildcard_match?(ref_name)
  end

  # Checks if two glob patterns have overlapping match sets.
  # Returns true if there exists ANY string that would match both
  # this pattern and the other_pattern.
  #
  # Patterns exceeding MAX_OVERLAP_PATTERN_LENGTH are rejected to
  # prevent stack overflow in the recursive algorithm.
  #
  # Examples:
  #   RefMatcher.new('prod*').overlaps?('production*')    # => true
  #   RefMatcher.new('release/*').overlaps?('release-*')  # => false
  def overlaps?(other_pattern)
    return false if @ref_name_or_pattern.blank? || other_pattern.blank?

    return false if @ref_name_or_pattern.length > MAX_OVERLAP_PATTERN_LENGTH ||
      other_pattern.length > MAX_OVERLAP_PATTERN_LENGTH

    other_is_wildcard = other_pattern.include?('*')

    # Neither has wildcards: exact match comparison
    return @ref_name_or_pattern == other_pattern if !wildcard? && !other_is_wildcard

    # Only one has a wildcard: delegate to pattern-to-literal matching
    return matches?(other_pattern) unless other_is_wildcard
    return other_matches_self?(other_pattern) unless wildcard?

    # Both have wildcards: check if their match sets overlap
    patterns_overlap?(@ref_name_or_pattern, other_pattern)
  end

  # Checks if this protected ref contains a wildcard
  def wildcard?
    @ref_name_or_pattern && @ref_name_or_pattern.include?('*')
  end

  private

  def other_matches_self?(other_pattern)
    # Check if other_pattern (which is a wildcard) matches our literal pattern.
    # This maintains symmetry: a.overlaps?(b) == b.overlaps?(a)
    # We inline the matching logic to avoid creating a new instance.
    # Note: blank other_pattern is already guarded in overlaps? before this is called.
    regex = build_wildcard_regex(other_pattern)
    regex.match?(@ref_name_or_pattern)
  end

  def exact_match?(ref_name)
    @ref_name_or_pattern == ref_name
  end

  def wildcard_match?(ref_name)
    return false unless wildcard?

    wildcard_regex.match?(ref_name)
  end

  def wildcard_regex
    @wildcard_regex ||= build_wildcard_regex(@ref_name_or_pattern)
  end

  # Determines whether two glob patterns (using '*' as wildcard) can both
  # match at least one common string. Uses a recursive algorithm with
  # memoization, running in O(len(p) * len(q)) time, and avoids substring
  # allocations by advancing index offsets.
  #
  # The algorithm works by simulating simultaneous consumption of a
  # hypothetical input string by both patterns:
  # - If both patterns are empty, the empty string matches both.
  # - If one pattern starts with '*', the wildcard can either consume
  #   nothing (advance past it) or consume one character of the other
  #   pattern's required input (advance the other pattern).
  # - If both start with the same literal character, advance both.
  # - Otherwise, no common string exists.
  def patterns_overlap?(pattern_a, pattern_b, start_a = 0, start_b = 0, memo = {})
    key = [start_a, start_b]
    return memo[key] if memo.key?(key)

    length_a = pattern_a.length
    length_b = pattern_b.length

    result =
      if start_a >= length_a && start_b >= length_b
        true
      elsif start_a >= length_a
        all_stars_from?(pattern_b, start_b)
      elsif start_b >= length_b
        all_stars_from?(pattern_a, start_a)
      else
        char_a = pattern_a.getbyte(start_a)
        char_b = pattern_b.getbyte(start_b)

        if char_a == STAR_BYTE
          patterns_overlap?(pattern_a, pattern_b, start_a + 1, start_b, memo) ||
            patterns_overlap?(pattern_a, pattern_b, start_a, start_b + 1, memo)
        elsif char_b == STAR_BYTE
          patterns_overlap?(pattern_a, pattern_b, start_a, start_b + 1, memo) ||
            patterns_overlap?(pattern_a, pattern_b, start_a + 1, start_b, memo)
        elsif char_a == char_b
          patterns_overlap?(pattern_a, pattern_b, start_a + 1, start_b + 1, memo)
        else
          false
        end
      end

    memo[key] = result
  end

  def all_stars_from?(pattern, start_index)
    index = start_index

    while index < pattern.length
      return false unless pattern.getbyte(index) == STAR_BYTE

      index += 1
    end

    true
  end

  def build_wildcard_regex(pattern)
    name = pattern.gsub('*', 'STAR_DONT_ESCAPE')
    quoted_name = Regexp.quote(name)
    regex_string = quoted_name.gsub('STAR_DONT_ESCAPE', '.*?')
    Gitlab::UntrustedRegexp.new("\\A#{regex_string}\\z")
  end
end
