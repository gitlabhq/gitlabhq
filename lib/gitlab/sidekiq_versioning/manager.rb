module Gitlab
  module SidekiqVersioning
    module Manager
      def initialize(options = {})
        options[:strict] = false
        options[:queues] = SidekiqVersioning.queues_with_versions(SidekiqConfig.expand_queues(options[:queues]))
        Sidekiq.logger.info "Listening on queues #{options[:queues].uniq.sort}"
        super
      end
    end
  end
end
