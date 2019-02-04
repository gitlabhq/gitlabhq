# frozen_string_literal: true

module Gitlab
  module TemporarilyAllow
    TEMPORARILY_ALLOW_MUTEX = Mutex.new

    def temporarily_allow(key)
      temporarily_allow_add(key, 1)
      yield
    ensure
      temporarily_allow_add(key, -1)
    end

    def temporarily_allowed?(key)
      if Gitlab::SafeRequestStore.active?
        temporarily_allow_request_store[key] > 0
      else
        TEMPORARILY_ALLOW_MUTEX.synchronize do
          temporarily_allow_ivar[key] > 0
        end
      end
    end

    private

    def temporarily_allow_ivar
      @temporarily_allow ||= Hash.new(0)
    end

    def temporarily_allow_request_store
      Gitlab::SafeRequestStore[:temporarily_allow] ||= Hash.new(0)
    end

    def temporarily_allow_add(key, value)
      if Gitlab::SafeRequestStore.active?
        temporarily_allow_request_store[key] += value
      else
        TEMPORARILY_ALLOW_MUTEX.synchronize do
          temporarily_allow_ivar[key] += value
        end
      end
    end
  end
end
