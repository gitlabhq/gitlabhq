# frozen_string_literal: true

ActiveContext.configure do |config|
  config.enabled = false
  config.indexing_enabled = false
  config.logger = ::Gitlab::ActiveContext::Logger.build
end
