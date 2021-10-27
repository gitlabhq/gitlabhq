# frozen_string_literal: true

module Gitlab
  module ActionCable
    class Config
      class << self
        def worker_pool_size
          ENV.fetch('ACTION_CABLE_WORKER_POOL_SIZE', 4).to_i
        end
      end
    end
  end
end
