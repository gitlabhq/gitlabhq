# frozen_string_literal: true

module Gitlab
  module Redis
    class ClusterRepositoryCache < ::Gitlab::Redis::Wrapper
      class << self
        # The data we store on RepositoryCache used to be stored on Cache.
        def config_fallback
          Cache
        end
      end
    end
  end
end
