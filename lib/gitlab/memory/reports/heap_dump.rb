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

        # This will be enabled once https://gitlab.com/gitlab-org/gitlab/-/issues/370077 is done.
        def active?
          false
        end

        # This is a no-op currently and will be implemented at a later time in
        # https://gitlab.com/gitlab-org/gitlab/-/issues/370077
        def run(writer)
          return false unless self.class.enqueued?

          true
        end
      end
    end
  end
end
