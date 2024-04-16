# frozen_string_literal: true

module Gitlab
  module Housekeeper
    class PushOptions
      attr_accessor :ci_skip

      def initialize
        @ci_skip = false
      end
    end
  end
end
