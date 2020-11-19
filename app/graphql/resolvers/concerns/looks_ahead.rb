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
    selection = node_selection

    includes = preloads.each.flat_map do |name, requirements|
      selection&.selects?(name) ? requirements : []
    end
    preloads = (unconditional_includes + includes).uniq

    return query if preloads.empty?

    query.preload(*preloads) # rubocop: disable CodeReuse/ActiveRecord
  end

  private

  def unconditional_includes
    []
  end

  def preloads
    {}
  end

  def node_selection
    return unless lookahead

    if lookahead.selects?(:nodes)
      lookahead.selection(:nodes)
    elsif lookahead.selects?(:edges)
      lookahead.selection(:edges).selection(:node)
    end
  end
end
