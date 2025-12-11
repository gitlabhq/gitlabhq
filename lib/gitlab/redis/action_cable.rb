# frozen_string_literal: true

module Gitlab
  module Redis
    class ActionCable < ::Gitlab::Redis::Wrapper
      class << self
        # We don't set a fallback as this is to be used during migration only
        def config_fallback
          nil
        end
      end
    end
  end
end
