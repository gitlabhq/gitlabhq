# frozen_string_literal: true

module Gitlab
  module Redis
    class RepositoryCache < ::Gitlab::Redis::Wrapper
      # The data we store on RepositoryCache used to be stored on Cache.
      def self.config_fallback
        Cache
      end
    end
  end
end
