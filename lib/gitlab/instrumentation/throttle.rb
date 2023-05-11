# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Throttle
      InstrumentationStorage = ::Gitlab::Instrumentation::Storage

      KEY = :instrumentation_throttle_safelist

      def self.safelist
        InstrumentationStorage[KEY]
      end

      def self.safelist=(name)
        InstrumentationStorage[KEY] = name
      end
    end
  end
end
