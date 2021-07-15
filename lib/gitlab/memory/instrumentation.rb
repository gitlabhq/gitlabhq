# frozen_string_literal: true

# This class uses a custom Ruby patch to allow
# a per-thread memory allocation tracking in a efficient manner
#
# This concept is currently tried to be upstreamed here:
# - https://github.com/ruby/ruby/pull/3978
module Gitlab
  module Memory
    class Instrumentation
      KEY_MAPPING = {
        total_allocated_objects: :mem_objects,
        total_malloc_bytes: :mem_bytes,
        total_mallocs: :mem_mallocs
      }.freeze

      MUTEX = Mutex.new

      def self.available?
        Thread.respond_to?(:trace_memory_allocations=) &&
          Thread.current.respond_to?(:memory_allocations)
      end

      def self.start_thread_memory_allocations
        return unless available?

        MUTEX.synchronize do
          # This method changes a global state
          Thread.trace_memory_allocations = true
        end

        # it will return `nil` if disabled
        Thread.current.memory_allocations
      end

      # This method returns a hash with the following keys:
      # - mem_objects:     number of allocated heap slots (as reflected by GC)
      # - mem_mallocs:     number of malloc calls
      # - mem_bytes:       number of bytes allocated by malloc for objects that did not fit
      #                    into a heap slot
      # - mem_total_bytes: number of bytes allocated for both objects consuming an object slot
      #                    and objects that required a malloc (mem_malloc_bytes)
      def self.measure_thread_memory_allocations(previous)
        return unless available?
        return unless previous

        current = Thread.current.memory_allocations
        return unless current

        # calculate difference in a memory allocations
        result = previous.to_h do |key, value|
          [KEY_MAPPING.fetch(key), current[key].to_i - value]
        end

        result[:mem_total_bytes] = result[:mem_bytes] + result[:mem_objects] * GC::INTERNAL_CONSTANTS[:RVALUE_SIZE]

        result
      end

      def self.with_memory_allocations
        previous = self.start_thread_memory_allocations
        yield
        self.measure_thread_memory_allocations(previous)
      end
    end
  end
end
