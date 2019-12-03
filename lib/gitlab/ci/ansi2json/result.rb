# frozen_string_literal: true

# Convertion result object class
module Gitlab
  module Ci
    module Ansi2json
      class Result
        attr_reader :lines, :state, :append, :truncated, :offset, :size, :total

        def initialize(lines:, state:, append:, truncated:, offset:, stream:)
          @lines = lines
          @state = state
          @append = append
          @truncated = truncated
          @offset = offset
          @size = stream.tell - offset
          @total = stream.size
        end
      end
    end
  end
end
