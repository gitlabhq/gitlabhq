# frozen_string_literal: true

class ProtectedRefMatcher
  def initialize(protected_ref)
    @protected_ref = protected_ref
  end

  # Returns all protected refs that match the given ref name.
  # This checks all records from the scope built up so far, and does
  # _not_ return a relation.
  #
  # This method optionally takes in a list of `protected_refs` to search
  # through, to avoid calling out to the database.
  def self.matching(type, ref_name, protected_refs: nil)
    (protected_refs || type.all).select { |protected_ref| protected_ref.matches?(ref_name) }
  end

  # Returns all branches/tags (among the given list of refs [`Gitlab::Git::Branch`])
  # that match the current protected ref.
  def matching(refs)
    refs.select { |ref| @protected_ref.matches?(ref.name) }
  end

  # Checks if the protected ref matches the given ref name.
  def matches?(ref_name)
    return false if @protected_ref.name.blank?

    exact_match?(ref_name) || wildcard_match?(ref_name)
  end

  # Checks if this protected ref contains a wildcard
  def wildcard?
    @protected_ref.name && @protected_ref.name.include?('*')
  end

  protected

  def exact_match?(ref_name)
    @protected_ref.name == ref_name
  end

  def wildcard_match?(ref_name)
    return false unless wildcard?

    wildcard_regex === ref_name
  end

  def wildcard_regex
    @wildcard_regex ||= begin
      name = @protected_ref.name.gsub('*', 'STAR_DONT_ESCAPE')
      quoted_name = Regexp.quote(name)
      regex_string = quoted_name.gsub('STAR_DONT_ESCAPE', '.*?')
      /\A#{regex_string}\z/
    end
  end
end
