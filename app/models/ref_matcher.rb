# frozen_string_literal: true

class RefMatcher
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

  # Checks if this protected ref contains a wildcard
  def wildcard?
    @ref_name_or_pattern && @ref_name_or_pattern.include?('*')
  end

  protected

  def exact_match?(ref_name)
    @ref_name_or_pattern == ref_name
  end

  def wildcard_match?(ref_name)
    return false unless wildcard?

    wildcard_regex.match?(ref_name)
  end

  def wildcard_regex
    @wildcard_regex ||= begin
      name = @ref_name_or_pattern.gsub('*', 'STAR_DONT_ESCAPE')
      quoted_name = Regexp.quote(name)
      regex_string = quoted_name.gsub('STAR_DONT_ESCAPE', '.*?')
      Gitlab::UntrustedRegexp.new("\\A#{regex_string}\\z")
    end
  end
end
