require 'prometheus/client'

module Gitlab
  module Metrics
    class ClientPerformanceStats
      include Gitlab::Metrics::Methods

      define_histogram :client_browser_timing do
        docstring "Client browser performance timing"
        base_labels event: nil
      end

      def self.record_browser_stats(stats)
        client_browser_timing.observe({ event: "connect" }, stats[:connect])
        client_browser_timing.observe({ event: "domainLookup" }, stats[:domainLookup])
        client_browser_timing.observe({ event: "request" }, stats[:request])
        client_browser_timing.observe({ event: "requestTtfb" }, stats[:requestTtfb])
        client_browser_timing.observe({ event: "interactive" }, stats[:interactive])
        client_browser_timing.observe({ event: "contentComplete" }, stats[:contentComplete])
        client_browser_timing.observe({ event: "loaded" }, stats[:loaded])
      end
    end
  end
end
