# frozen_string_literal: true

module Test
  module Queues
    class Mock
      include ::ActiveContext::Concerns::Queue

      def self.number_of_shards
        4
      end
    end
  end
end
