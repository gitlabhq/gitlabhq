# frozen_string_literal: true

module Gitlab
  module Patch
    module RedisStoreFactory
      def create
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- patched code references @options in redis-store
        opt = @options
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
        return Gitlab::Redis::ClusterStore.new(opt) if opt[:nodes]

        super
      end
    end
  end
end
