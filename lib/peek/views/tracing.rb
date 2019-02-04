# frozen_string_literal: true

module Peek
  module Views
    class Tracing < View
      def results
        {
          tracing_url: Gitlab::Tracing.tracing_url
        }
      end
    end
  end
end
