# frozen_string_literal: true

ActiveContext.configure do |config|
  config.enabled = true
  config.indexing_enabled = true
  config.logger = ::Gitlab::ActiveContext::Logger.build

  config.queue_classes = []
  config.queue_classes.concat([::Ai::ActiveContext::Queues::Code]) if Gitlab.ee?
end
