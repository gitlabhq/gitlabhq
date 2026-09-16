# frozen_string_literal: true

module PolicyStoreRegoHelpers
  # Valid Rego of exactly `length` characters, padded with a single comment line.
  def scope_rego_of(length)
    program = "#{Gitlab::PolicyStore::ScopeTranspiler::PACKAGE}\n\ndefault applies := false\n"
    empty_comment_line = "#\n"
    padding = 'p' * (length - program.length - empty_comment_line.length)

    "#{program}##{padding}\n"
  end
end
