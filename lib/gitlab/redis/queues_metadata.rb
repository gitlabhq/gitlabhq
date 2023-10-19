# frozen_string_literal: true

module Gitlab
  module Redis
    class QueuesMetadata < ::Gitlab::Redis::Wrapper
      class << self
        def config_fallback
          Queues
        end
      end
    end
  end
end
