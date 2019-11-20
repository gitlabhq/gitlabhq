# frozen_string_literal: true

module Gitlab
  # The SidekiqMiddleware class is responsible for configuring the
  # middleware stacks used in the client and server middlewares
  module SidekiqMiddleware
    # The result of this method should be passed to
    # Sidekiq's `config.server_middleware` method
    # eg: `config.server_middleware(&Gitlab::SidekiqMiddleware.server_configurator)`
    def self.server_configurator(metrics: true, arguments_logger: true, memory_killer: true, request_store: true)
      lambda do |chain|
        chain.add Gitlab::SidekiqMiddleware::Monitor
        chain.add Gitlab::SidekiqMiddleware::Metrics if metrics
        chain.add Gitlab::SidekiqMiddleware::ArgumentsLogger if arguments_logger
        chain.add Gitlab::SidekiqMiddleware::MemoryKiller if memory_killer
        chain.add Gitlab::SidekiqMiddleware::RequestStoreMiddleware if request_store
        chain.add Gitlab::SidekiqMiddleware::BatchLoader
        chain.add Gitlab::SidekiqMiddleware::CorrelationLogger
        chain.add Gitlab::SidekiqMiddleware::InstrumentationLogger
        chain.add Gitlab::SidekiqStatus::ServerMiddleware
      end
    end

    # The result of this method should be passed to
    # Sidekiq's `config.client_middleware` method
    # eg: `config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)`
    def self.client_configurator
      lambda do |chain|
        chain.add Gitlab::SidekiqStatus::ClientMiddleware
        chain.add Gitlab::SidekiqMiddleware::CorrelationInjector
      end
    end
  end
end
