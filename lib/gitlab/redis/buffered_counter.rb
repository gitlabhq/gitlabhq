# frozen_string_literal: true

module Gitlab
  module Redis
    class BufferedCounter < ::Gitlab::Redis::Wrapper
      class << self
        def config_fallback
          SharedState
        end
      end
    end
  end
end
