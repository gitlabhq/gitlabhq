# frozen_string_literal: true

module Peek
  module Views
    class Memory < View
      MEM_TOTAL_LABEL = 'Total'
      MEM_OBJECTS_LABEL = 'Objects allocated'
      MEM_MALLOCS_LABEL = 'Allocator calls'
      MEM_BYTES_LABEL = 'Large allocations'

      def initialize(options = {})
        super

        @thread_memory = {}
      end

      def results
        return thread_memory if thread_memory.empty?

        {
          calls: byte_string(thread_memory[:mem_total_bytes]),
          summary: {
            MEM_OBJECTS_LABEL => number_string(thread_memory[:mem_objects]),
            MEM_MALLOCS_LABEL => number_string(thread_memory[:mem_mallocs]),
            MEM_BYTES_LABEL => byte_string(thread_memory[:mem_bytes])
          },
          details: [
            {
              item_header: MEM_TOTAL_LABEL,
              item_content: "Total memory use of this request. This includes both occupancy of existing heap slots " \
                            "as well as newly allocated memory due to large objects. Not adjusted for freed memory. " \
                            "Lower is better."
            },
            {
              item_header: MEM_OBJECTS_LABEL,
              item_content: "Total number of objects allocated by the Ruby VM during this request. " \
                            "Not adjusted for objects that were freed again. Lower is better."
            },
            {
              item_header: MEM_MALLOCS_LABEL,
              item_content: "Total number of times Ruby had to call `malloc`, the C memory allocator. " \
                            "This is necessary for objects that are too large to fit into a 40 Byte slot in Ruby's managed heap. " \
                            "Lower is better."
            },
            {
              item_header: MEM_BYTES_LABEL,
              item_content: "Memory allocated for objects that did not fit into a heap slot. " \
                            "Not adjusted for memory that was freed again. Lower is better."
            }
          ]
        }
      end

      private

      attr_reader :thread_memory

      def setup_subscribers
        subscribe 'process_action.action_controller' do
          # Ensure that Peek will see memory instrumentation in `results` by triggering it when
          # a request is done processing. Peek itself hooks into the same notification:
          # https://github.com/peek/peek/blob/master/lib/peek/railtie.rb
          Gitlab::InstrumentationHelper.instrument_thread_memory_allocations(thread_memory)
        end
      end

      def byte_string(bytes)
        ActiveSupport::NumberHelper.number_to_human_size(bytes)
      end

      def number_string(num)
        ActiveSupport::NumberHelper.number_to_human(num, units: { thousand: 'k', million: 'M', billion: 'B' })
      end
    end
  end
end
