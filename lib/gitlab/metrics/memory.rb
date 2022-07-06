# frozen_string_literal: true

module Gitlab
  module Metrics
    module Memory
      extend self

      HEAP_SLOTS_PER_PAGE = GC::INTERNAL_CONSTANTS[:HEAP_PAGE_OBJ_LIMIT]

      def gc_heap_fragmentation(gc_stat = GC.stat)
        1 - (gc_stat[:heap_live_slots] / (HEAP_SLOTS_PER_PAGE * gc_stat[:heap_eden_pages].to_f))
      end
    end
  end
end
