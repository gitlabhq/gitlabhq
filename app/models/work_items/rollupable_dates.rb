# frozen_string_literal: true

module WorkItems
  class RollupableDates
    include ::Gitlab::Utils::StrongMemoize

    def initialize(source, can_rollup:)
      @source = source
      @can_rollup = can_rollup
    end

    def fixed?
      return true unless @can_rollup
      return true if source.start_date_is_fixed && source.start_date_fixed.present?
      return true if source.due_date_is_fixed && source.due_date_fixed.present?
      return true if source.start_date_is_fixed && source.due_date_is_fixed

      false
    end
    strong_memoize_attr :fixed?

    def start_date
      return source.start_date_fixed if fixed?

      source.start_date
    end

    def start_date_fixed
      source.start_date_fixed
    end

    def due_date
      return source.due_date_fixed if fixed?

      source.due_date
    end

    def due_date_fixed
      source.due_date_fixed
    end

    private

    attr_reader :source
  end
end

WorkItems::RollupableDates.prepend_mod
