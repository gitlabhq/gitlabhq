# frozen_string_literal: true

module Gitlab
  module Json
    class << self
      def parse(*args)
        adapter.parse(*args)
      end

      def parse!(*args)
        adapter.parse!(*args)
      end

      def dump(*args)
        adapter.dump(*args)
      end

      def generate(*args)
        adapter.generate(*args)
      end

      def pretty_generate(*args)
        adapter.pretty_generate(*args)
      end

      private

      def adapter
        ::JSON
      end
    end
  end
end
