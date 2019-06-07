# frozen_string_literal: true

module Peek
  module Views
    class Tracing < View
      def results
        tracing_url = Labkit::Tracing.tracing_url(Gitlab.process_name)

        { tracing_url: tracing_url }
      end
    end
  end
end
