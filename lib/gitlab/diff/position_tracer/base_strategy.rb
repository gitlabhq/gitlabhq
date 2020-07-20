# frozen_string_literal: true

module Gitlab
  module Diff
    class PositionTracer
      class BaseStrategy
        attr_reader :tracer

        delegate \
          :project,
          :diff_file,
          :ac_diffs,
          :bd_diffs,
          :cd_diffs,
          to: :tracer

        def initialize(tracer)
          @tracer = tracer
        end

        def trace(position)
          raise NotImplementedError
        end
      end
    end
  end
end
