# frozen_string_literal: true

module Gitlab
  module Memory
    module Reports
      class HeapDump
        class << self
          def enqueue!
            @write_heap_dump = true
          end

          def enqueued?
            !!@write_heap_dump
          end
        end

        def name
          'heap_dump'
        end

        def active?
          Feature.enabled?(:report_heap_dumps, type: :ops)
        end

        def run(writer)
          return false unless self.class.enqueued?

          ObjectSpace.dump_all(output: writer)

          true
        end
      end
    end
  end
end
