# frozen_string_literal: true

module Ci
  class BuildTrace
    attr_reader :trace, :build

    delegate :state, :append, :truncated, :offset, :size, :total, to: :trace, allow_nil: true
    delegate :id, :status, :complete?, to: :build, prefix: true

    def initialize(build:, stream:, state:)
      @build = build

      if stream.valid?
        stream.limit
        @trace = Gitlab::Ci::Ansi2json.convert(stream.stream, state)
      end
    end

    def lines
      @trace&.lines
    end
  end
end
