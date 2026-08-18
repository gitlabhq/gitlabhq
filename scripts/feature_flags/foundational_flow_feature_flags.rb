# frozen_string_literal: true

require 'ripper'

# Extracts the `feature_flag:` value out of an `Ai::Catalog::FoundationalFlow`
# definition file's `configuration` method, without booting Rails.
#
# These definitions gate themselves through a `feature_flag:` key inside the
# hash their `configuration` method returns, looked up dynamically via
# `Feature.disabled?(feature_flag.to_sym, ...)`, which cannot be resolved
# statically by Rubocop. Matching is scoped to `configuration`'s returned
# hash specifically -- a `feature_flag:`-shaped pair anywhere else in the
# file (e.g. an unrelated method's keyword argument) is ignored.
module FoundationalFlowFeatureFlags
  module_function

  def parse(source)
    Ripper.sexp(source)
  end

  def feature_flag_name(sexp)
    configuration_hash = find_configuration_hash(sexp)
    return unless configuration_hash

    value_node = hash_pair_value(configuration_hash, 'feature_flag')
    return unless value_node

    literal_value(value_node, sexp)
  end

  def find_configuration_hash(node)
    return unless node.is_a?(Array)

    if node[0] == :def && node[1].is_a?(Array) && node[1][0] == :@ident && node[1][1] == 'configuration'
      return last_statement_hash(node[3])
    end

    node.each do |child|
      found = find_configuration_hash(child)
      return found if found
    end

    nil
  end

  def last_statement_hash(bodystmt)
    statements = bodystmt[1] if bodystmt.is_a?(Array)
    last_statement = statements.last if statements.is_a?(Array)

    last_statement if last_statement.is_a?(Array) && last_statement[0] == :hash
  end

  def hash_pair_value(hash_node, key_name)
    assoclist = hash_node[1]
    return unless assoclist.is_a?(Array) && assoclist[0] == :assoclist_from_args

    pairs = assoclist[1]
    return unless pairs.is_a?(Array)

    pair = pairs.find do |candidate|
      candidate.is_a?(Array) && candidate[0] == :assoc_new &&
        candidate[1].is_a?(Array) && candidate[1][0] == :@label && candidate[1][1] == "#{key_name}:"
    end

    pair && pair[2]
  end

  # Resolves a plain string/symbol literal, or a constant assigned one
  # earlier in the same file (following a chain, if any). Anything else --
  # an external/undefined constant, a method call, an interpolated string --
  # can't be resolved statically, and is left as nil.
  def literal_value(node, root, seen_constants = [])
    return unless node.is_a?(Array)

    case node[0]
    when :string_literal
      string_literal_value(node[1])
    when :symbol_literal
      symbol_literal_value(node[1])
    when :var_ref
      constant_value(node, root, seen_constants)
    end
  end

  def constant_value(node, root, seen_constants)
    const_name = constant_name(node)
    return if !const_name || seen_constants.include?(const_name)

    assigned_value = find_constant_assignment(root, const_name)
    return unless assigned_value

    literal_value(assigned_value, root, seen_constants + [const_name])
  end

  def constant_name(var_ref_node)
    ident = var_ref_node[1]
    ident[1] if ident.is_a?(Array) && ident[0] == :@const
  end

  def find_constant_assignment(node, const_name)
    return unless node.is_a?(Array)

    if node[0] == :assign && node[1].is_a?(Array) && node[1][0] == :var_field
      field = node[1][1]
      return node[2] if field.is_a?(Array) && field[0] == :@const && field[1] == const_name
    end

    node.each do |child|
      found = find_constant_assignment(child, const_name)
      return found if found
    end

    nil
  end

  def string_literal_value(content_node)
    return unless content_node.is_a?(Array) && content_node[0] == :string_content
    return unless content_node[1..].all? { |part| part.is_a?(Array) && part[0] == :@tstring_content }

    content_node[1..].map { |part| part[1] }.join # rubocop:disable Rails/Pluck -- standalone script, no Rails loaded
  end

  def symbol_literal_value(symbol_node)
    return unless symbol_node.is_a?(Array) && symbol_node[0] == :symbol

    ident = symbol_node[1]
    ident[1] if ident.is_a?(Array)
  end
end
