# frozen_string_literal: true

module ClickHouse
  module Client
    class BindIndexManager
      def initialize(start_index = 1)
        @current_index = start_index
      end

      def next_bind_str
        bind_str = "$#{@current_index}"
        @current_index += 1
        bind_str
      end
    end
  end
end
