module Gitlab
  module Metrics
    class SidekiqTransaction
      def initialize(worker_class)
        @worker_class = worker_class
      end

      protected

      def labels
        { controller: worker.class.name, action: 'perform' }
      end
    end
  end
end
