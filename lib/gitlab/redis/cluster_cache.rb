# frozen_string_literal: true

module Gitlab
  module Redis
    class ClusterCache < ::Gitlab::Redis::Wrapper
      class << self
        def config_fallback
          Cache
        end
      end
    end
  end
end
