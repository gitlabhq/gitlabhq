# frozen_string_literal: true

module LooksAhead
  extend ActiveSupport::Concern

  included do
    extras [:lookahead]
    attr_accessor :lookahead
  end

  def resolve(**args)
    self.lookahead = args.delete(:lookahead)

    resolve_with_lookahead(**args)
  end

  def apply_lookahead(query)
    all_preloads = (unconditional_includes + filtered_preloads).uniq

    return query if all_preloads.empty?

    query.preload(*all_preloads) # rubocop: disable CodeReuse/ActiveRecord
  end

  private

  def unconditional_includes
    []
  end

  def preloads
    {}
  end

  def nested_preloads
    {}
  end

  def filtered_preloads
    nodes = node_selection

    return [] unless nodes&.selected?

    selected_fields = nodes.selections.map(&:name)
    root_level_preloads = preloads_from_node_selection(selected_fields, preloads)

    root_level_preloads + nested_filtered_preloads(nodes, selected_fields)
  end

  def nested_filtered_preloads(nodes, selected_root_fields)
    return [] if nested_preloads.empty?

    nested_preloads.each_with_object([]) do |(root_field, fields), result|
      next unless selected_root_fields.include?(root_field)

      selected_fields = nodes.selection(root_field).selections.map(&:name)

      result << preloads_from_node_selection(selected_fields, fields)
    end.flatten
  end

  def preloads_from_node_selection(selected_fields, fields)
    fields.each_with_object([]) do |(field, requirements), result|
      result << requirements if selected_fields.include?(field)
    end.flatten
  end

  def node_selection(selection = lookahead)
    return selection unless selection&.selected?
    return selection.selection(:edges).selection(:node) if selection.selects?(:edges)

    # Will return a NullSelection object if :nodes is not a selection. This
    # is better than returning nil as we can continue chaining selections on
    # without raising errors.
    selection.selection(:nodes)
  end
end
