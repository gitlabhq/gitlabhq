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
        @trace = Gitlab::Ci::Ansi2json.convert(
          stream.stream,
          state,
          verify_state: Feature.enabled?(:sign_and_verify_ansi2json_state, build.project)
        )
      end
    end

    def lines
      @trace&.lines
    end
  end
end
