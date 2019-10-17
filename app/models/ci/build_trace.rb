# frozen_string_literal: true

module Ci
  class BuildTrace
    CONVERTERS = {
      html: Gitlab::Ci::Ansi2html,
      json: Gitlab::Ci::Ansi2json
    }.freeze

    attr_reader :trace, :build

    delegate :state, :append, :truncated, :offset, :size, :total, to: :trace, allow_nil: true
    delegate :id, :status, :complete?, to: :build, prefix: true

    def initialize(build:, stream:, state:, content_format:)
      @build = build
      @content_format = content_format

      if stream.valid?
        stream.limit
        @trace = CONVERTERS.fetch(content_format).convert(stream.stream, state)
      end
    end

    def json?
      @content_format == :json
    end

    def html?
      @content_format == :html
    end

    def json_lines
      @trace&.lines if json?
    end

    def html_lines
      @trace&.html if html?
    end
  end
end
