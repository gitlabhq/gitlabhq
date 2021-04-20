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
    selection = node_selection

    preloads.each.flat_map do |name, requirements|
      selection&.selects?(name) ? requirements : []
    end
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
