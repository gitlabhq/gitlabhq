# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      module Callbacks
        mattr_accessor :metrics_host_gauge_proc, :track_exception_proc
        def self.configure!
          yield(self)
        end

        def self.metrics_host_gauge(labels, value)
          metrics_host_gauge_proc&.call(labels, value)
        end

        def self.track_exception(ex)
          track_exception_proc&.call(ex)
        end
      end
    end
  end
end
