# frozen_string_literal: true

module Gitlab
  module Cluster
    class PumaWorkerKillerObserver
      def initialize
        @counter = Gitlab::Metrics.counter(:puma_killer_terminations_total, 'Number of workers terminated by PumaWorkerKiller')
      end

      # returns the Proc to be used as the observer callback block
      def callback
        method(:log_termination)
      end

      private

      def log_termination(worker)
        @counter.increment
      end
    end
  end
end
