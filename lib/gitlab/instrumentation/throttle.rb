# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Throttle
      KEY = :instrumentation_throttle_safelist

      def self.safelist
        Gitlab::SafeRequestStore[KEY]
      end

      def self.safelist=(name)
        Gitlab::SafeRequestStore[KEY] = name
      end
    end
  end
end
