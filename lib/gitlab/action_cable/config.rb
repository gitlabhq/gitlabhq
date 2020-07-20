# frozen_string_literal: true

module Gitlab
  module ActionCable
    class Config
      class << self
        def in_app?
          Gitlab::Utils.to_boolean(ENV.fetch('ACTION_CABLE_IN_APP', false))
        end

        def worker_pool_size
          ENV.fetch('ACTION_CABLE_WORKER_POOL_SIZE', 4).to_i
        end
      end
    end
  end
end
