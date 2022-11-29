# frozen_string_literal: true

module Gitlab
  module Memory
    module Reports
      class JemallocStats
        def name
          'jemalloc_stats'
        end

        def run(writer)
          return unless active?

          Gitlab::Memory::Jemalloc.dump_stats(writer)
        end

        def active?
          Feature.enabled?(:report_jemalloc_stats, type: :ops)
        end
      end
    end
  end
end
