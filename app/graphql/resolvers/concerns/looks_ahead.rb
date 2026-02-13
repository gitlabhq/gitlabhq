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

  def filtered_preloads
    nodes = node_selection

    return [] unless nodes&.selected?

    preloads.each_with_object([]) do |(fields, associations_to_preload), result|
      lookahead_node = nodes

      Array.wrap(fields).each do |field|
        next if lookahead_node.nil?

        lookahead_node = lookahead_node.selections.find { |s| s.name == field }
      end

      result << associations_to_preload if lookahead_node&.selected?
    end.flatten
  end

  def node_selection(selection = lookahead)
    return selection unless selection&.selected?
    return selection if selection.field.type.list?
    return selection.selection(:edges).selection(:node) if selection.selects?(:edges)

    # Will return a NullSelection object if :nodes is not a selection. This
    # is better than returning nil as we can continue chaining selections on
    # without raising errors.
    selection.selection(:nodes)
  end
end
