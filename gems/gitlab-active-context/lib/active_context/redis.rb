# frozen_string_literal: true

module ActiveContext
  class Redis
    def self.with_redis(&blk)
      Gitlab::Redis::SharedState.with(&blk)
    end
  end
end
